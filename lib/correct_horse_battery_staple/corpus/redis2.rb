require 'bigdecimal'
require 'hiredis'
require 'redis'

class CorrectHorseBatteryStaple::Corpus::Redis2 < CorrectHorseBatteryStaple::Corpus::Redis
  MAX_ITERATIONS = 1000

  def size
    @size ||= db.zcard(@percentile_key)
  end



  ## our own collection operations
  ## optimized pick implementations - they do NOT support :filter, though

  def pick(count, options = {})
    percentile_range = options[:percentile]
    length_range     = options[:word_length]
    tempkey = nil

    if percentile_range && percentile_range.begin == 0 && percentile_range.end == 100
      percentile_range = nil
    end

    pick_sset_random(@words_key, 4)

    if (!percentile_range && !length_range)
      get_words_for_ids(pick_random_words(count))
    else
      sets = []
      sets << make_subset_spec(@percentile_key, percentile_range) if percentile_range

      # this isn't correct because lenprod_key will have values in the range 18...19
      # sets << make_subset_spec(@lenprod_key, length_range)         if length_range
      if length_range
        sets << [@lenprod_key, ["-inf", "(#{length_range.begin}"],
                               ["#{length_range.end.floor + 1}", "inf"]]
      end

      # returns union set key
      tempkey = subset_and_union(sets)
      # STDERR.puts "result count in #{tempkey} is #{db.zcard(tempkey)}"

      get_words_for_ids(pick_sset_random(tempkey, count))
    end
  ensure
    db.del tempkey if tempkey
  end

  def make_subset_spec(key, range)
    [key, ["-inf", "(#{range.begin}"], ["(#{range.end}", "inf"]]
  end

  def make_subset(spec)
    key = gensym_temp
    source_key = spec.shift
    db.zunionstore(key, [source_key])
    db.expire(key, 180)
    spec.each do |(min, max)|
      db.zremrangebyscore(key, min, max)
    end
    key
  end

  def subset_and_union(specs)
    result_key = gensym_temp
    db.multi do
      keys = specs.map do |spec|
        make_subset(spec)
      end
      db.zinterstore(result_key, keys)
      db.del(*keys)
    end
    db.expire(result_key, 1800)
    result_key
  end

  def pick_sset_random(key, count)
    max = db.zcard(key)
    db.multi do
      count.times.map do
        rnd = random_number(max)
        db.zrange(key, rnd, rnd)
      end
    end.flatten
  end
end
