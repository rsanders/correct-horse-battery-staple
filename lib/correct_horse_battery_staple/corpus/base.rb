require 'bigdecimal'

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


  # this is the core password picker method
  def pick(count, options = {})
    CorrectHorseBatteryStaple::StatisticalArray.new(entries.map {|entry| entry.frequency })
  end

  def entropy_per_word
    Math.log(count) / Math.log(2)
  end


  def words
    execute_filters.map {|entry| entry.word }
  end

  def frequencies
    CorrectHorseBatteryStaple::StatisticalArray.new(entries.map {|entry| entry.frequency })
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
