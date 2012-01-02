require 'bigdecimal'
require 'hiredis'
require 'redis'
require 'set'

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
    @size ||= db.zcard(@words_key)
  end



  ## our own collection operations

  def entries
    table
  end

  def sorted_entries
    entries.sort
  end


  ## optimized pick implementations - they do NOT support :filter, though

  def pick(count, options = {})
    percentile_range = options[:percentile]
    length_range     = options[:word_length]

    if percentile_range && percentile_range.begin == 0 && percentile_range.end == 100
      percentile_range = nil
    end

    if (!percentile_range && !length_range)
      get_words_for_ids(pick_random_words(count))
    else
      sets = []
      sets << get_word_ids_in_zset(@percentile_key, percentile_range) if percentile_range
      sets << get_word_ids_in_zset(@length_key, length_range)         if length_range

      candidates = (sets.length == 1 ? sets[0] : intersection(*sets))
      get_words_for_ids(array_sample(candidates, count))
    end
  end

  def pick_random_words(count)
    count.times.map do
      idx = random_number(size)-1
      db.zrange(@words_key, idx, idx)[0]
    end
  end

  def intersection(*sets)
    sets.reduce {|a,b| a & b}
  end
  memoize :intersection

  def get_word_ids_in_zset(key, range)
    db.zrangebyscore(key, range.begin, range.end)
  end
  memoize :get_word_ids_in_zset

  def get_words_for_ids(ids)
    ids.map {|id| CorrectHorseBatteryStaple::Word.new(:word => get_word_by_id(id)) }
  end


  def close
    super
  end

  protected

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

end
