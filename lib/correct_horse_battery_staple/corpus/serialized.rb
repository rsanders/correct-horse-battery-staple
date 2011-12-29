require 'bigdecimal'
require 'json'

class CorrectHorseBatteryStaple::Corpus::Serialized < CorrectHorseBatteryStaple::Corpus::Base
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

  def each(&block)
    @table.each &block
  end

  def result
    self.class.new(execute_filters).tap do |new_corpus|
      new_corpus.original_size = self.original_size
      new_corpus.recalculate
    end
  end

  #
  # Note that this mutates the Word objects so that stats for the
  # source table after a filter.result sequence will no longer be
  # valid. Also, any references to the original array will now be
  # pointing to updated data.
  #
  def recalculate
    super
    
    @table.each_with_index do |entry, index|
      entry.rank                      = size - index
      entry.distance                  = (entry.frequency-frequency_mean)/frequency_stddev
      entry.probability               = entry.frequency / weighted_size
      entry.distance_probability      = (entry.probability - probability_mean) / probability_stddev
      entry.percentile                = (index-0.5)/size * 100
    end

    self
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

  def table
    @table
  end

  protected

  def execute_filters
    return @table if @filters.nil? || @filters.empty?
    @table.select &compose_filters(@filters)
  ensure
    reset
  end

  def method_missing(name, *args, &block)
    @table.__send__(name, *args, &block)
  end

end
