require 'bigdecimal'
require 'json'
require 'set'
require 'kdtree'

module CorrectHorseBatteryStaple::Backend::IsamKD
  INITIAL_PRELUDE_LENGTH = 4096

  F_PRELUDE_AT_END = 1

  def self.included(base)
    base.extend ClassMethods
    base.send :include, InstanceMethods
  end

  module ClassMethods
  end

  module InstanceMethods
    def fix_stats(stats)
      stats.each do |k,v|
        if v.respond_to?(:nan?) && v.nan?
          stats[k] = -1
        end
      end
      stats
    end

    def page_size
      4096
    end

    # many MMUs in default mode and modern highcap drives have 4k pages/blocks
    def round_up(val, blocksize=page_size)
      [(val.to_f/blocksize).ceil, 1].max * blocksize
    end

    def write_corpus_to_io(corpus, io=STDOUT)
      io.rewind

      # includes prefix length byte
      @word_length = corpus.reduce(0) { |m, e| m > e.word.length ? m : e.word.length } + 1
      @freq_length = 4
      @entry_length = @word_length + @freq_length

      stats = fix_stats(corpus.stats)
      corpus_word_count = corpus.length

      prelude = {
        "wlen"           => @word_length,
        "flen"           => 4,
        "entrylen"       => @word_length + @freq_length,
        "sort"           => "frequency",
        "n"              => corpus_word_count,
        "stats"          => stats,
        "flags"          => 0,
        "records_length" => "0000000000",
        "offset_records" => "0000000000",
        "offset_index1"  => "0000000000",
        "offset_index2"  => "0000000000"
      }

      prelude_json_length = prelude.to_json.length
      prelude["offset_records"] = offset_records = round_up(prelude_json_length+8.0)

      prelude["records_length"] = records_length = corpus_word_count * prelude["entrylen"]
      offset_index1 = prelude["offset_records"] +
        round_up(records_length, page_size)

      prelude["offset_index1"]  = offset_index1

      io.write([offset_records, prelude_json_length, prelude.to_json].
               pack("NNA#{offset_records-8}"))

      corpus.each_with_index do |w, index|
        io.write(s=[w.word.length, w.word, w.frequency].pack("Ca#{@word_length-1}N"))
      end

      pad(offset_index1 - (offset_records + records_length), io)
      write_kdtree(corpus, io)
    end

    def pad(size, io)
      io.write([].pack("x#{size}"))
    end

    def write_kdtree(corpus, io)
      i = -1
      k = KDTree.new(
                     corpus.entries.map {|w| [
                                              len2coord(w.word.length.to_f),
                                              w.percentile.to_f,
                                              i+=1
                                             ]
                     }
                     )

      k.persist(io)
    end

    # make the search space more square by increasing the length of
    # the "word length" axis
    def len2coord(len)
      len * 10
    end
    
    def binwrite(*args)
      method = io.respond_to?(:binwrite) ? :binwrite : :write
      io.send(method, *args)
    end

    def openmode
      IO.respond_to?(:binwrite) ? "wb:ASCII-8BIT" : "w"
    end


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

    # def initialize(filename, stats = nil)
    #   @filename = filename
    #   @file = CorrectHorseBatteryStaple::Util.open_binary(filename, "r")
    #   parse_prelude
    # end

    def precache(max = -1)
      return if max > -1 && file_size(@file) > max
      @file.seek 0
      @file = StringIO.new @file.read, "r"
    end

    def file_size(file)
      (file.respond_to?(:size) ? file.size : file.stat.size)
    end

    def prelude
      @prelude || parse_prelude
    end

    def parse_prelude
      @file.seek 0
      prelude_buf = @file.read(INITIAL_PRELUDE_LENGTH)

      # byte offset of first record from beginning of file
      # total length of JSON string (without padding)
      (@record_offset, @prelude_len)  = prelude_buf.unpack("NN")

      # read more if our initial read didn't slurp in the entire prelude
      if @prelude_len > prelude_buf.length
        prelude_buf += @file.read(@prelude_len - prelude_buf.length)
      end

      @prelude = JSON.parse( prelude_buf.unpack("@8a#{@prelude_len}")[0] ) || {}

      # includes prefix length byte
      @word_length      = @prelude["wlen"]     || raise(ArgumentError, "Word length is not defined!")

      # as network byte order int
      @frequency_length = @prelude["flen"]     || 4

      # total length of record
      @entry_length     = @prelude["entrylen"] || raise(ArgumentError, "Prelude does not include entrylen!")

      @offset_index1    = @prelude["offset_index1"] || raise(ArgumentError, "No index offset!")

      @records_length   = @prelude["records_length"] || raise(ArgumentError, "No records length!")

      @entry_count      = @prelude["n"] || raise(ArgumentError, "Number of records not included!")
      
      load_stats_from_hash(@prelude["stats"]) if @prelude["stats"]

      @prelude
    end

    def load_kdtree
      # @file.seek(@offset_index1)
      # STDERR.puts "sig is #{@file.read(4)}"

      @file.seek(@offset_index1)
      KDTree.new @file
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

    def get_word_by_idx(i)
      chunk = nth_chunk(i, records_string)
      parse_record(chunk)
    end

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
      @entry_count ||= records_size / @entry_length
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

      result = []
      found_indexes = []
      iterations = 0
      while result.size < count && iterations < 1000
        len = random_in_range(options[:word_length])
        pct = random_in_range(options[:percentile])
        word_idx = @kdtree.nearest(len2coord(len), pct)
        unless found_indexes.include?(word_idx)
          found_indexes << word_idx
          word = get_word_by_idx(word_idx)
          if options[:word_length].include?(word.word.length)
            result << word
          else
            STDERR.puts "non-qualifying word: #{word.word.length}"
          end
        end
        iterations += 1
      end
      STDERR.puts "iterations was #{iterations}" if iterations > count+1

      # validate that we succeeded
      raise "Cannot find #{count} words matching criteria" if result.length < count

      result
    end


    
    ## file I/O

    def records_size
      @records_length
    end

    def file_string
      @file.is_a?(StringIO) ? @file.string : file_range_read(nil)
    end

    def file_range_read(file_range = nil)
      file_range ||= 0...file_size(@file)
      pos = @file.tell
      @file.seek(file_range.first)
      @file.read(range_count(file_range))
    ensure
      @file.seek(pos)
    end
    # memoize :file_range_read

    # returns a string representing the record-holding portion of the file
    def records_string
      @records_string ||=
        record_range_read(0 ... records_size)
    end

    def record_range_read(record_range = nil)
      record_range ||= 0...records_size
      file_range_read((record_range.first + @record_offset)...(range_count(record_range) + @record_offset))
    end
    # memoize :record_range_read

    def record_percentile_range_read(percentile_range)
      record_range = record_range_for_percentile(percentile_range)
      record_range_read(record_range)
    end

    
    ## rather than using a StatisticalArray, we do direct indexing into the file/string
    def percentile_index(percentile, round=true)
      r = percentile.to_f/100 * count + 0.5
      round ? r.round : r
    end

    def record_range_for_percentile(range)
      range = Range.new(range - 0.5, range + 0.5) if range.is_a?(Numeric)
      (percentile_index(range.begin, false).floor * @entry_length ...
       percentile_index(range.end,   false).ceil * @entry_length)
    end
  end
end
