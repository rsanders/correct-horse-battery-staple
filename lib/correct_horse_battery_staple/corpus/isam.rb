require 'bigdecimal'
require 'json'
require 'set'

#
#
# Format of header:
#
# 0..3    -  OB - offset of body start in bytes; network byte order
# 4..7    -  LP - length of prelude in network byte order
# 8..OB-1 -  P  - JSON-encoded prelude hash and space padding
# OB..EOF -  array of fixed size records as described in prelude
#
# Contents of Prelude (after JSON decoding):
#
# P["wlen"]     - length of word part of record
# P["flen"]     - length of frequency part of record (always 4 bytes)
# P["entrylen"] - length of total part of record
# P["n"]        - number of records
# P["sort"]     - field name sorted by (word or frequency)
# P["stats"]    - corpus statistics
#
# Format of record:
#
# 2 bytes              - LW - actual length of word within field
# P["wlen"] bytes      - LW bytes of word (W) + P["wlen"]-LW bytes of padding
# P["flen"] (4) bytes  - frequency as network byte order long
#

class CorrectHorseBatteryStaple::Corpus::Isam < CorrectHorseBatteryStaple::Corpus::Base
  INITIAL_PRELUDE_LENGTH = 512

  def initialize(filename, stats = nil)
    @filename = filename
    parse_prelude
  end

  def self.memoize(method)
    old_method = "_#{method}_unmemoized".to_sym
    miss_object = Object.new
    alias_method old_method, method
    define_method method do |*args, &block|
      @_memoize_cache ||= {}
      if block
        raise ArgumentError, "You cannot call a memoized method with a block! #{method}"
      end
      value = @_memoize_cache.fetch(args, miss_object)
      if value === miss_object
        value = @_memoize_cache[args] = send(old_method, *args)
      end
      value
    end
  end

  def prelude
    @prelude || parse_prelude 
  end

  def stats
    @prelude["stats"] || {}
  end

  def parse_prelude
    prelude_buf = binread(@filename, INITIAL_PRELUDE_LENGTH)

    # byte offset of first record from beginning of file
    # total length of JSON string (without padding)
    (@record_offset, @prelude_len)  = prelude_buf.unpack("NN")

    # read more if our initial read didn't slurp in the entire prelude
    if @prelude_len > prelude_buf.length
      prelude_buf += binread(@filename,
                             @prelude_len - prelude_buf.length,
                             INITIAL_PRELUDE_LENGTH)
    end

    @prelude = JSON.parse( prelude_buf.unpack("@8a#{@prelude_len}")[0] ) || {}

    # includes prefix length byte
    @word_length      = @prelude["wlen"]     or raise "Word length is not defined!"

    # as network byte order int
    @frequency_length = @prelude["flen"]     or 4

    # total length of record
    @entry_length     = @prelude["entrylen"] or raise "Prelude does not include entrylen!"

    @prelude
  end

  # factory-ish constructor
  def self.read(filename)
    self.new filename
  end


  ## parsing

  #
  # Parse a record into an array of [word, frequency] IFF the word
  # fits into the length_range or length_range is nil
  #
  def parse_record_into_array(string, index, length_range = nil)
    chunk = nth_chunk(index, string)
    raise "No chunk for index #{index}" unless chunk
    actual_word_length = chunk.unpack("C")[0]
    # STDERR.puts "awl = #{actual_word_length}, chunk = #{chunk[0..4].inspect}"
    if !length_range || length_range.include?(actual_word_length)
      # returns [word, frequency]
      chunk.unpack("xa#{actual_word_length}@#{@word_length}N")
    else
      nil
    end
  end

  #
  # Parse a record into a Word object, which can be provided or will otherwise
  # be constructed as needed fourth arg is a length range which can act as a
  # filter; if not satisfied, nil will be returned
  #
  def parse_record(string, index=0,
                   word=CorrectHorseBatteryStaple::Word.new(:word => ""),
                   length_range = nil)
    bare = parse_record_into_array(string, index, length_range)
    return nil unless bare
    word.word = bare[0]
    word.frequency = bare[1]
    word
  end

  def word_length(chunk_string)
    chunk_string.unpack("C")
  end

  # return a string representing the nth_record
  def nth_chunk(n, string)
    string[@entry_length * n, @entry_length]
  end
  # memoize :nth_chunk

  ## some core Enumerable building blocks

  def each(&block)
    string = records_string
    max_index = size - 1
    index = 0
    while index < max_index
      yield parse_record(string, index)
      index += 1
    end
  end

  def count; size; end
  def size
    @size ||= records_size / @entry_length
  end


  ## our Corpus Enumerablish abstract methods
  
  # we presume that the ISAM file has been sorted
  def sorted_entries
    @sorted_entries ||= entries
  end


  ## optimized pick - does NOT support :filter, though
  def pick(count, options = {})
    # incompat check
    raise NotImplementedError, "ISAM does not support :filter option" if options[:filter]

    # options parsing
    rng            = options[:rng] || self.rng
    string         = file_percentile_range_read(options[:percentile] || (0..100))
    range_size     = string.length / @entry_length
    max_iterations = [options[:max_iterations] || 1000, count*10].max

    if range_size < count
      raise ArgumentError, "Percentile range contains fewer words than requested count"
    end

    # the real work
    result         = _pick(string, count, options[:word_length], max_iterations)

    # validate that we succeeded
    raise "Cannot find #{count} words matching criteria" if result.count < count

    result
  end

  def _pick(string, count, length_range, max_iterations)
    result = []
    iterations = 0

    # don't bother reading already read words
    skip_cache = Set.new
    range_size = string.length / @entry_length

    # don't cons!
    entry = CorrectHorseBatteryStaple::Word.new :word => ""
    while result.count < count && iterations < max_iterations
      i = rng.random_number(range_size)
      # STDERR.puts "checking #{i} in #{length_range} strlen = #{string.length} range_size = #{range_size}"
      unless skip_cache.include? i
        pr = parse_record(string, i, entry, length_range)
        # STDERR.puts "pr is #{pr.inspect}"
        if pr
          result << pr.dup
        else
          skip_cache << i
        end
      end
      iterations += 1
    end
    result
  end


  ## file I/O

  def binread(*args)
    method = IO.respond_to?(:binread) ? :binread : :read
    IO.send(method, *args)
  end

  def records_size
    @records_size ||= (File.size(@filename) - @record_offset)
  end

  # returns a string representing the record-holding portion of the file
  def records_string
    @records_string ||=
      binread(@filename, records_size, @record_offset)
  end

  def file_range_read(file_range)
    binread(@filename, file_range.count, file_range.first + @record_offset)
  end
  memoize :file_range_read

  def file_percentile_range_read(percentile_range)
    file_range = file_range_for_percentile(percentile_range)
    file_range_read(file_range)
  end


  ## rather than using a StatisticalArray, we do direct indexing into the file/string
  def percentile_index(percentile, round=true)
    r = percentile.to_f/100 * count + 0.5
    round ? r.round : r
  end

  def file_range_for_percentile(range)
    range = Range.new(range - 0.5, range + 0.5) if range.is_a?(Numeric)
    (percentile_index(range.begin, false).floor * @entry_length ...
     percentile_index(range.end,   false).ceil * @entry_length)
  end


end
