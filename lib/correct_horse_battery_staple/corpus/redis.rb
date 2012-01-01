require 'bigdecimal'
require 'redis'

class CorrectHorseBatteryStaple::Corpus::Redis < CorrectHorseBatteryStaple::Corpus::Base
  include CorrectHorseBatteryStaple::Backend::Redis

  MAX_ITERATIONS = 1000

  attr_accessor :dest
  attr_accessor :options

  def initialize(dest)
    self.dest    = dest
    self.options = {}
    parse_uri(dest)

    load_stats
  end

  def self.read(file)
    self.new file
  end

  ## some core Enumerable building blocks

  def each(&block)
    entries.each &block
  end

  def size
    @size ||= @db.execute("select count(*) from entries").first.first
  end



  ## our own collection operations

  def entries
    @entries ||= table
  end

  def sorted_entries
    entries
  end


  ## optimized pick implementations - they do NOT support :filter, though

  # def pick(count, options = {})
  # end

  # def get_words_for_ids(ids)
  #   ids = Array(ids)
  #   rows = @db.execute("select #{COLUMNS.join(", ")} from entries where id in (#{ids.join(',')})")

  #   words = []
  #   ids.each do |id|
  #     words << rows.find {|r| r[0] == id }
  #   end
  #   words.map {|row| word_from_row(row)}
  # end


  def close
    super
  end

  protected

  # COLUMNS = %w[id word frequency idx rank percentile]

  def table
    percentiles = db.zrangebyscore(@percentile_key, -1, 101, :withscores => true)
    frequencies = db.zrangebyscore(@frequency_key, -1, 99999999, :withscores => true)

    phash = {}
    fhash = {}
    (0...percentiles.length / 2).each do |index|
      base = index * 2
      phash[percentiles[base]] = percentiles[base+1]
    end
    (0...frequencies.length / 2).each do |index|
      base = index * 2
      fhash[frequencies[base]] = frequencies[base+1]
    end

    count = phash.length
    index = 0
    phash.keys.map do |w|
      word_from_hash :word => w, :percentile => phash[w].to_f, :index => (index+=1),
                     :rank => count-index+1, :frequency => fhash[w].to_f
    end
  end

  def word_from_hash(hash)
    CorrectHorseBatteryStaple::Word.new(hash)
  end

  def word_from_row(row)
    CorrectHorseBatteryStaple::Word.new(:word => row[1], :frequency => row[2],
                                        :index => row[3], :rank => row[4],
                                        :percentile => row[5])
  end

  def load_stats
    #rows = @db.execute "select name, value from stats"
    #load_stats_from_hash(rows.reduce({}) {|m, (key, val)| m.merge(key => val.to_f)})
  end
end
