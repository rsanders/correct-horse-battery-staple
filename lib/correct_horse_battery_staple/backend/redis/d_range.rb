#
# Represents a list of items corresponding to a square area of items
# formed by a range on axis 1 and a range on axis 2 of numbers
# associated with an item.  In other words, this composes two
# different data about an item into a single score in a Redis sorted
# set, and allow that area to be treated as a single logical ordered
# list of items.
#
# This is used to construct a single score out of a word's length
# and percentile ranking.  The length is the "outer" score and
# ranges (generally) from 3..18 or thereabouts in integral steps.
# Percentiles exist as fractional parts of the score added to the
# base word length.  So, to address the items in a sorted set
# with the word length from 5..8 and percentile range 20..30,
# you would (in the Writer::Redis class) generate a Sorted set
# in which every word has a score with an integer and fractional
# part.  The word "the" which appeared in the 95th percentile would
# have a score of 3.95.
#
# Once defined, this class allows the following operations:
#
# - counting the total # of items in the 2d bounding box
# - picking the nth item from the (virtual) sorted list
#
#

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
      if cib > 0 && n >= minpos && n <= maxpos
        (min, max) = minmax_for_base(base)
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
    #noinspection RubyHashKeysTypesInspection
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
