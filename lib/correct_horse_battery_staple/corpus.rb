if RUBY_VERSION.start_with? "1.8"
  require 'faster_csv'
  CSVLIB = FasterCSV
else
  require 'csv'
  CSVLIB = CSV
end

class CorrectHorseBatteryStaple::Corpus

  def self.read_csv(file)
    table = self.new CSVLIB.table(file)
  end

  def initialize(table)
    @table   = table
    @filters = []
  end

  def filter(&block)
    @filters << block
    self
  end

  def entropy_per_word
    Math.log(length) / Math.log(2)
  end
  
  def reset
    @filters = []
  end

  def words
    execute_filters.map {|row| row[:word]}
  end

  def result
    self.class.new execute_filters
  end

  def frequencies
    StatisticalArray.new(execute_filters.map {|row| row[:frequency]})
  end

  def composed_filters(filters)
    return nil if !filters || filters.empty?
    filters.reduce {|prev, current| lambda {|value| prev.call(value) && current.call(value) } }
  end

  protected

  def execute_filters
    return @table if @filters.nil? || @filters.empty?
    @table.select &composed_filters(@filters)
  ensure
    reset
  end

  def method_missing(name, *args, &block)
    @table.__send__(name, *args, &block)
  end

end
