require 'bigdecimal'
require 'securerandom'

class CorrectHorseBatteryStaple::Corpus::Base < CorrectHorseBatteryStaple::Corpus
  attr_accessor :frequency_mean, :frequency_stddev
  attr_accessor :probability_mean, :probability_stddev
  attr_accessor :original_size
  attr_accessor :weighted_size

  include CorrectHorseBatteryStaple::Common
  include Enumerable

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


  def sorted_entries
    entries.sort
  end

  #
  # this is the core password picker method. it is not especially
  # efficient but it is relatively generic.  If a corpus supports
  # Enumerable, it will work.
  #
  def pick(count, options = {})
    array = CorrectHorseBatteryStaple::StatisticalArray.new(sorted_entries)
    rng = options[:rng] || self.rng

    filters = Array(options[:filter])

    if options[:percentile]
      range = array.index_range_for_percentile(options[:percentile])
    else
      range = 0..array.size-1
    end
    range_size = range.count

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
    while result.count < count && iterations < max_iterations
      i = rng.random_number(range_size)
      entry = array[i]
      if entry && (!filter || filter.call(entry))
        result << entry
      end
      iterations += 1
    end

    raise "Cannot find #{count} words matching criteria" if result.count < count
    result
  end



  def rng
    @rng ||= SecureRandom
  end

  def words
    execute_filters.map {|entry| entry.word }
  end

  def frequencies
    CorrectHorseBatteryStaple::StatisticalArray.new(entries.map {|entry| entry.frequency })
  end

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

  def recalculate
    size        = self.count
    frequencies = self.frequencies

    # corpus-wide statistics
    self.weighted_size  = frequencies.reduce(BigDecimal.new("0"), :+)
    (self.probability_mean, self.probability_stddev)    =
      CorrectHorseBatteryStaple::StatisticalArray.new(frequencies.map do |freq|
        (freq/weighted_size) * 100
      end).mean_and_standard_deviation

    (self.frequency_mean, self.frequency_stddev) = frequencies.mean_and_standard_deviation

    self
  end

  def stats
    {:frequency_mean => frequency_mean, :frequency_stddev => frequency_stddev,
      :probability_mean => probability_mean, :probability_stddev => probability_stddev,
      :size => count, :original_size => original_size,
      :weighted_size => weighted_size.to_f}
  end

  alias :length :count


  protected

  # this is an exceptionally inefficient version
  def execute_filters
    return entries if @filters.nil? || @filters.empty?
    entries.select &compose_filters(@filters)
  ensure
    reset
  end

end
