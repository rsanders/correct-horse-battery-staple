require 'bigdecimal'
require 'json'

class CorrectHorseBatteryStaple::Corpus::Serialized < CorrectHorseBatteryStaple::Corpus::Base
  attr_reader   :table

  if RUBY_VERSION.start_with? "1.8"
    require 'faster_csv'
    CSVLIB = FasterCSV
  else
    require 'csv'
    CSVLIB = CSV
  end

  def initialize(table, stats = nil)
    @table   = CorrectHorseBatteryStaple::StatisticalArray.cast(table.sort, true)
    @stats   = stats
    @filters = []

    self.original_size = @table.size
  end

  ## some core Enumerable building blocks

  def each(&block)
    table.each &block
  end

  def size
    table.length
  end

  def entries
    table
  end

  def sorted_entries
    table
  end

  ## serialization
  # reading

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

  # writing

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

  def write_isam(io)
    sorted_entries.each_with_index do |w, index|
      io.print sprintf("%-40s%10d", w.word, w.frequency || 0) if
        w.word.length <= 40
    end
  end

  def write(io, fformat=nil)
    raise ArgumentError, "Cannot determine file format for output" if !fformat || fformat.empty?
    send "write_#{fformat}", io
  end

  protected

  def method_missing(name, *args, &block)
    @table.__send__(name, *args, &block)
  end

end
