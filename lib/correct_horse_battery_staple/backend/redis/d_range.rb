class CorrectHorseBatteryStaple::Backend::Redis::DRange
  include CorrectHorseBatteryStaple::Memoize
  def initialize(db, key, outer, inner, divisor=100)
    @db = db
    @key = key
    @outer = outer
    @inner = inner
    @divisor = divisor
    @counts = {}
  end

  def dump
    iterate_ranges do |min, max|
      cnt = @db.zcount(@key, min, max)
      [min, max, cnt]
    end
  end
  
  def count
    # @db.multi do
    #   iterate_ranges do |min, max|
    #     zcount(min, max)
    #   end
    # end.reduce(:+)
    precache_counts
    @counts.values.reduce(:+)
  end
  memoize :count

  def pick_nth(n)
    precache_counts
    return nil if n > count-1

    pos = 0
    @outer.each do |base|
      cib = count_in_base(base)
      minpos = pos
      maxpos = pos + cib
      # STDERR.puts "pos = #{pos}, cib = #{cib}, minpos = #{minpos}, maxpos = #{maxpos}, base = #{base}"
      if cib > 0 && n >= minpos && n <= maxpos
        (min, max) = minmax_for_base(base)
        # STDERR.puts "   min = #{min}, max = #{max}, limit = [#{n-pos}, 1]"
        return @db.zrangebyscore(@key, min, max,
                                 :limit => [n-pos, 1])[0]
      end
      pos += cib
    end
    return nil
  end

  protected

  def precache_counts
    return if @precached_counts
    counts = @db.multi do
      @outer.each do |base|
        zcount(*minmax_for_base(base))
      end
    end
    @counts = Hash[@outer.to_a.zip(counts)]
    @precached_counts = true
    @counts
  end

  def count_in_base(b)
    @counts[b] ||= zcount(*minmax_for_base(b))
  end

  def minmax_for_base(base)
    [base + @inner.begin / (@divisor.to_f),
     base + @inner.end / (@divisor.to_f)]
  end

  def zcount(min, max)
    @db.zcount(@key, min, max)
  end

  def iterate_ranges
    @outer.map do |base|
      (min, max) = minmax_for_base(base)
      yield min, max
    end
  end

end
