require 'bigdecimal'

class CorrectHorseBatteryStaple::Corpus::Base < CorrectHorseBatteryStaple::Corpus
  #attr_accessor :frequency_mean, :frequency_stddev
  #attr_accessor :probability_mean, :probability_stddev
  #attr_accessor :original_size
  #attr_accessor :weighted_size

  include CorrectHorseBatteryStaple::Common
  include Enumerable

  def filter(&block)
    @filters << block
    self
  end

  def entropy_per_word
    Math.log(count) / Math.log(2)
  end

  def reset
    @filters = []
  end

  def words
    execute_filters.map {|entry| entry.word }
  end

  def words
    raise NotImplementedError
  end

  def each(&block)
    raise NotImplementedError
  end

  def entries
    to_a
  end

  def result
    raise NotImplementedError
  end

  def frequencies
    CorrectHorseBatteryStaple::StatisticalArray.new(entries.map {|entry| entry.frequency })
  end

  # create a single composed function of all the filters
  def compose_filters(filters)
    return nil if !filters || filters.empty?
    filters.reduce do |prev, current|
      lambda {|value| prev.call(value) && current.call(value) }
    end
  end

  #
  # Note that this mutates the Word objects so that stats for the
  # source table after a filter.result sequence will no longer be
  # valid. Also, any references to the original array will now be
  # pointing to updated data.
  #
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

  def execute_filters
    raise NotImplementedError
  end
end
