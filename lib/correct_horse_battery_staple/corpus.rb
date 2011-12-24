require 'faster_csv'

class CorrectHorseBatteryStaple::Corpus

  def self.read_csv(file)
    table = self.new FasterCSV.table(file)
  end

  def initialize(table)
    @table   = table
    @filters = []
  end

  def filter(&block)
    @filters << block
    self
  end

  def words
    execute_filters.map {|row| row[:word]}
  end

  def result
    self.class.new execute_filters
  end

  protected

  def execute_filters
    return @table if @filters.nil? || @filters.empty?

    (filters, @filters) = [@filters, []]

    filters.reduce(@table) do |initial, filter|
      FasterCSV::Table.new initial.select(&filter)
    end
  end

  def method_missing(name, *args, &block)
    @table.__send__(name, *args, &block)
  end

end
