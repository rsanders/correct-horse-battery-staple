require 'bigdecimal'
require 'json'
require 'set'

class CorrectHorseBatteryStaple::Corpus::Isam < CorrectHorseBatteryStaple::Corpus::Base

  WORD_LENGTH = 40
  FREQUENCY_LENGTH = 10

  ENTRY_LENGTH = WORD_LENGTH + FREQUENCY_LENGTH

  def initialize(filename, stats = nil)
    @filename = filename
  end

  def self.read(filename)
    self.new filename
  end

  def file_size
    @file_size ||= File.size @filename
  end

  def file_io
    @file_io ||= open(@filename)
  end

  def file_string
    @file_string ||= open(@filename).read
  end

  def parse_bare(string,index=0)
    offset = index * ENTRY_LENGTH
    word = string[offset...(offset+WORD_LENGTH)].strip
    frequency = string[(offset+WORD_LENGTH)...(offset+WORD_LENGTH+FREQUENCY_LENGTH)].strip.to_i
    [word, frequency]
  end

  def parse_entry(string, index=0)
    bare = parse_bare(string, index)
    CorrectHorseBatteryStaple::Word.new :word => bare[0], :frequency => bare[1]
  end

  ## some core Enumerable building blocks

  def each(&block)
    string = file_string
    string_length = string.length
    size = string_length / WORD_LENGTH
    index = 0
    while index < size
      yield parse_entry(string, index)
      index += 1
    end
  end

  def count
    size
  end

  def size
    @size ||= file_size / ENTRY_LENGTH
  end

  def sorted_entries
    @sorted_entries ||= entries
  end

  def percentile_index(percentile, round=true)
    r = percentile.to_f/100 * count + 0.5
    round ? r.round : r
  end

  def file_range_for_percentile(range)
    range = Range.new(range - 0.5, range + 0.5) if range.is_a?(Numeric)
    (percentile_index(range.begin, false).floor * ENTRY_LENGTH ..
     percentile_index(range.end,   false).ceil * ENTRY_LENGTH)
  end

  ## optimized pick
  def pick(count, options = {})
    rng = options[:rng] || self.rng

    filters = Array(options[:filter])

    string     = cached_file_range_read(options[:percentile] || (0..100))

    range_size = string.length / ENTRY_LENGTH

    if range_size < count
      raise ArgumentError, "Percentile range contains fewer words than requested count"
    end

    if options[:word_length]
      wl = options[:word_length]
      filters << lambda {|entry| wl.include? entry.word.length }
    end
    filter = filters.empty? ? nil : compose_filters(filters)

    max_iterations = options[:max_iterations] || 1000

    result = []
    iterations = 0
    bad_cache = Set.new
    entry = CorrectHorseBatteryStaple::Word.new :word => ""
    while result.count < count && iterations < max_iterations
      i = rng.random_number(range_size)
      unless bad_cache.include? i
        bare = parse_bare(string, i)
        entry.word = bare[0]
        entry.frequency = bare[1]
        if entry && (!filter || filter.call(entry))
          result << entry.dup
        else
          bad_cache << i
        end
      end
      iterations += 1
    end

    raise "Cannot find #{count} words matching criteria" if result.count < count
    result
  end

  def cached_file_range_read(percentile_range)
    if @cached_range != percentile_range
      file_range = file_range_for_percentile(percentile_range)
      readmethod = IO.respond_to?(:binread) ? :binread : :read
      @cached_string = IO.send(readmethod, @filename, file_range.count, file_range.first)
      @cached_range  = percentile_range
    end
    @cached_string
  end
end
