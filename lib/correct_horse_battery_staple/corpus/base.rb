require 'bigdecimal'
# require 'securerandom'
require 'forwardable'

class CorrectHorseBatteryStaple::Corpus::Base < CorrectHorseBatteryStaple::Corpus
  extend Forwardable
  
  attr_accessor :frequency_mean, :frequency_stddev
  attr_accessor :probability_mean, :probability_stddev
  attr_accessor :original_size
  attr_accessor :weighted_size

  include CorrectHorseBatteryStaple::Common
  include CorrectHorseBatteryStaple::Memoize
  include Enumerable

  def initialize(*args)
    initialize_backend_variables if respond_to?(:initialize_backend_variables)
  end
  
  def self.read(dest)
    self.new dest
  end
  
  # you MUST override this method for Enumerable to use

  def each(&block)
    raise NotImplementedError
  end

  # other methods you should implement if possible:
  #
  # Enumerable
  #  size
  #
  # CHBS::Corpus
  #  pick
  #  words
  #  frequencies
  #

  def count(*args, &block)
    if args.length > 0 || block
      super(*args, &block)
    else
      size
    end 
  end
  

  def sorted_entries
    entries.sort
  end

  # return all the candidates for a given set of options
  def candidates(options = {})
    return size if !options || options.empty?
    filter = filter_for_options(options)
    return size unless filter
    entries.select {|entry| filter.call(entry) }
  end

  def count_candidates(options = {})
    return size if !options || options.empty?
    filter = filter_for_options(options)
    return size unless filter

    count = 0
    each do |entry|
      count += 1 if filter.call(entry)
    end
    count
  end
  memoize :count_candidates



  #
  # this is the core password picker method. it is not especially
  # efficient but it is relatively generic.  If a corpus supports
  # Enumerable, it will work.
  #
  def pick(count, options = {})
    array = CorrectHorseBatteryStaple::StatisticalArray.new(sorted_entries)

    filters = Array(options[:filter])

    if options[:percentile]
      range = array.index_range_for_percentile(options[:percentile])
    else
      range = 0..array.size-1
    end
    range_size = range_size(range)

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
    while result.length < count && iterations < max_iterations
      i = random_number(range_size)
      entry = array[i + range.first]
      if entry && (!filter || filter.call(entry))
        result << entry
      end
      iterations += 1
    end

    raise "Cannot find #{count} words matching criteria" if result.length < count
    result
  end



  def words
    execute_filters.map {|entry| entry.word }
  end
  memoize :words

  # no-op for serialized forms
  def precache(max=0)
  end

  def frequencies
    CorrectHorseBatteryStaple::StatisticalArray.new(entries.map {|entry| entry.frequency })
  end
  memoize :frequencies

  def entropy_per_word
    Math.log(count) / Math.log(2)
  end

  # filtering

  def filter(&block)
    (@filters ||= []) << block
    self
  end

  def reset
    @filters = []
  end

  # create a single composed function of all the filters
  def compose_filters(filters)
    return nil if !filters || filters.empty?
    filters.reduce do |prev, current|
      lambda {|value| prev.call(value) && current.call(value) }
    end
  end

  def result
    return self if @filters.empty?

    self.class.new(execute_filters).tap do |new_corpus|
      new_corpus.original_size = self.original_size
    end
  end


  ## statistics

  def load_stats_from_hash(hash)
    hash.each do |k,v|
      setter = "#{k}=".to_sym
      send setter, v if respond_to?(setter)
    end
  end

  def recalculate
    size        = self.size
    frequencies = self.frequencies

    # corpus-wide statistics
    self.weighted_size  = frequencies.reduce(BigDecimal.new("0"), :+)
    (self.probability_mean, self.probability_stddev)    =
      CorrectHorseBatteryStaple::StatisticalArray.new(frequencies.map do |freq|
        (freq/weighted_size) * 100
      end).mean_and_standard_deviation

    (self.frequency_mean, self.frequency_stddev) = frequencies.mean_and_standard_deviation

      # stats              = corpus.stats
      # size               = corpus.size
      # frequency_mean     = corpus.frequency_mean
      # frequency_stddev   = corpus.frequency_stddev
      # weighted_size      = corpus.weighted_size
      # probability_mean   = corpus.probability_mean
      # probability_stddev = corpus.probability_stddev

    each_with_index do |entry, index|
      entry.rank                      = size - index
      entry.distance                  = (entry.frequency-frequency_mean)/frequency_stddev
      entry.probability               = entry.frequency / weighted_size
      entry.distance_probability      = (entry.probability - probability_mean) / probability_stddev
      entry.percentile                = (index-0.5)/size * 100
    end

    self
  end

  def stats
    {:frequency_mean => frequency_mean, :frequency_stddev => frequency_stddev,
      :probability_mean => probability_mean, :probability_stddev => probability_stddev,
      :size => count, :original_size => original_size,
      :weighted_size => weighted_size.to_f}
  end

  def inspect
    <<INSPECT
Type: #{self.class.name}
Entry count: #{count}

Stats:
#{stats.map {|k,v| "  #{k}: #{v}\n" }.join("") }
INSPECT
  end
  
  alias :length :count


  protected

  #
  # Return the number of distinct objects within the Range.
  # This assumes plain vanilla ranges, though it does respect .. vs ...
  #
  # Why? Range#count is basically #to_a.count, which is INSANE
  #
  def range_count(r)
    (r.last - r.first +
     (r.exclude_end? ? 0 : (r.first > r.last ? -1 : 1))
     ).abs
  end
  alias :range_size :range_count

  #
  # Given a filter, return all Word objects in this Corpus that the
  # filter accepts.
  #
  # this is an exceptionally inefficient version
  def execute_filters
    return entries if @filters.nil? || @filters.empty?
    entries.select(&compose_filters(@filters))
  ensure
    reset
  end

  #
  # Return a single lambda that will return true/false given a Word object
  #
  # Respects the :word_length, :percentile, and :filter options
  # :word_length and :percentile should be Range objects
  # :filter can be a single Proc/lambda or an array of them
  #
  def filter_for_options(options = {})
    return nil if !options || options.empty?

    filters = Array(options[:filter])
    if options[:percentile]
      p_range = options[:percentile]
      filters << lambda {|entry| p_range.include? entry.percentile }
    end

    if options[:word_length]
      wl_range = options[:word_length]
      filters << lambda {|entry| wl_range.include? entry.word.length }
    end

    filters.empty? ? nil : compose_filters(filters)
  end
  memoize :filter_for_options

end

# Random.srand(SecureRandom.random_number)
