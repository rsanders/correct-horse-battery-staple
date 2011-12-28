require 'bigdecimal'

class CorrectHorseBatteryStaple::Corpus
  include CorrectHorseBatteryStaple::Common

  attr_reader   :table

  attr_accessor :frequency_mean, :frequency_stddev
  attr_accessor :probability_mean, :probability_stddev
  attr_accessor :original_size
  attr_accessor :weighted_size

  if RUBY_VERSION.start_with? "1.8"
    require 'faster_csv'
    CSVLIB = FasterCSV
  else
    require 'csv'
    CSVLIB = CSV
  end

  def self.read_csv(file)
    self.new CSVLIB.table(file).map {|row| CorrectHorseBatteryStaple::Word.new(row.to_hash) }
  end

  def self.read_json(file)
    json = JSON.parse(open(file).read)
    self.new(json["corpus"].map {|hash| CorrectHorseBatteryStaple::Word.new(hash)},
             json["stats"])
  end

  def self.read_marshal(file)
    Marshal.load(open(file).read)
  end

  def self.read(filename, fformat=nil)
    if ! fformat
      fformat = File.extname(filename)[1..-1]
    end
    raise ArgumentError, "Cannot determine file format for #{filename}" if !fformat || fformat.empty?
    send "read_#{fformat}", filename
  end

  def initialize(table, stats = nil)
    @table   = CorrectHorseBatteryStaple::StatisticalArray.cast(table)
    @stats   = stats
    @filters = []

    self.original_size = @table.length
    recalculate
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

  def each_entry(&block)
    @table.each &block
  end

  def result
    self.class.new(execute_filters).tap do |new_corpus|
      new_corpus.original_size = self.original_size
      new_corpus.recalculate
    end
  end

  def frequencies
    CorrectHorseBatteryStaple::StatisticalArray.new(execute_filters.map {|entry| entry.frequency })
  end

  # create a single composed function of all the filters
  def composed_filters(filters)
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
    size = self.size

    # corpus-wide statistics
    self.weighted_size  = frequencies.reduce(BigDecimal.new("0"), :+)
    (self.probability_mean, self.probability_stddev)    = CorrectHorseBatteryStaple::StatisticalArray.new(frequencies.map do |freq|
        (freq/weighted_size) * 100
      end).mean_and_standard_deviation
    (self.frequency_mean, self.frequency_stddev)    = frequencies.mean_and_standard_deviation

    @table.each_with_index do |entry, index|
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
      :size => size, :original_size => original_size,
      :weighted_size => weighted_size.to_f}
  end

  def size
    @table.length
  end

  # serialization

  def write_csv(io)
    io.puts "index,rank,word,frequency,percentile,distance,probability,distance_probability"
    @table.each_with_index do |w, index|
      io.puts sprintf("%d,%d,\"%s\",%d,%.4f,%.6f,%.8f,%.8f\n",
        index, w.rank, w.word, w.frequency || 0,
        w.percentile || 0, w.distance || 0, w.probability || 0, w.distance_probability || 0)
    end
  end

  def write_json1(io)
    io.write({"stats" => stats, "corpus" => @table }.to_json)
  end

  def write_json(io)
    io.print '{"stats": '
    io.print stats.to_json
    io.print ', "corpus": ['
    i = 0
    @table.each do |word|
      io.puts "," if i >= 1
      io.print(word.to_hash.to_json)
      i += 1
    end
    io.puts "]\n}"
  end

  def write_marshal(io)
    io.write Marshal.dump(self)
  end

  def write(io, fformat=nil)
    raise ArgumentError, "Cannot determine file format for output" if !fformat || fformat.empty?
    send "write_#{fformat}", io
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
