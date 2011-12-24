require 'faster_csv'

class CorrectHorseBatteryStaple::Corpus

  def self.read_csv(file)
    table = self.new FasterCSV.table(file)
  end

  def initialize(table)
    @table   = table
    @filters = []

    table.convert {|field, info| info.header == :word ? field.to_s : field }
  end

  def filter(&block)
    @filters << block
    self
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

  protected

  def execute_filters
    return @table if @filters.nil? || @filters.empty?

    @filters.reduce(@table) do |initial, filter|
      FasterCSV::Table.new initial.select(&filter)
    end
  ensure
    reset
  end

  def method_missing(name, *args, &block)
    @table.__send__(name, *args, &block)
  end

end
