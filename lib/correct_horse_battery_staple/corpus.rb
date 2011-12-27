if RUBY_VERSION.start_with? "1.8"
  require 'faster_csv'
  CSVLIB = FasterCSV
else
  require 'csv'
  CSVLIB = CSV
end

class CorrectHorseBatteryStaple::Corpus

  def self.read_csv(file)
    self.new CSVLIB.table(file).map {|hash| CorrectHorseBatteryStaple::Word.new(hash) }
  end

  def self.read_json(file)
    json = JSON.parse(open(file).read)
    self.new(json["corpus"].map {|hash| CorrectHorseBatteryStaple::Word.new(hash)},
             json["stats"])
  end

  def self.read(filename, format="json")
    send "read_#{format}", filename
  end

  def initialize(table, stats = nil)
    @table   = table
    @stats   = stats
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
    execute_filters.map {|entry| entry.word }
  end

  def result
    self.class.new execute_filters
  end

  def frequencies
    StatisticalArray.new(execute_filters.map {|entry| entry.frequency })
  end

  # create a single composed function of all the filters
  def composed_filters(filters)
    return nil if !filters || filters.empty?
    filters.reduce do |prev, current|
      lambda {|value| prev.call(value) && current.call(value) }
    end
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
