module CorrectHorseBatteryStaple

  class StatisticalArray
    def initialize(array, sorted=false)
      @obj    = array
      @sorted = sorted
    end

    def self.cast(array, sorted=false)
      if array.is_a?(CorrectHorseBatteryStaple::StatisticalArray)
        array
      else
        CorrectHorseBatteryStaple::StatisticalArray.new(array, sorted)
      end
    end

    def sort!
      @obj    = @obj.sort unless @sorted
      @sorted = true
      self
    end

    def sort_by!(&block)
      @obj     = @obj.sort_by(&block)
      @sorted  = true
      self
    end

    def method_missing(name, *args, &block)
      @obj.__send__(name, *args, &block)
    end

    def mean
      inject(0) { |sum, x| sum += x } / size.to_f
    end
    alias :average :mean

    def sum
      reduce(:+)
    end

    def sort(&block)
      return super(&block) if block || !@sorted
      self
    end

    def standard_deviation(m = mean)
      variance = inject(0) { |variance, x| variance += (x - m) ** 2 }
      return Math.sqrt(variance/(size-1))
    end

    def mean_and_standard_deviation
      return m=mean, standard_deviation(m)
    end

    def percentile_index(percentile, round=true)
      r = percentile.to_f/100 * length + 0.5
      round ? r.round : r
    end

    def index_range_for_percentile(range)
      range = Range.new(range - 0.5, range + 0.5) if range.is_a?(Numeric)
      sort!

      (percentile_index(range.begin, false).floor ..
          percentile_index(range.end,   false).ceil)
    end

    def select_percentile(range)
      slice(index_range_for_percentile(range))
    end

  end
end
