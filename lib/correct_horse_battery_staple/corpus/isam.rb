require 'bigdecimal'
require 'json'
require 'set'

#
#
# Format of header:
#
# 0..3    -  OB - offset of body start in bytes; network byte order
# 4..7    -  LP - length of prelude in network byte order
# 8..OB-1 -  P  - JSON-encoded prelude hash and space padding
# OB..EOF -  array of fixed size records as described in prelude
#
# Contents of Prelude (after JSON decoding):
#
# P["wlen"]     - length of word part of record
# P["flen"]     - length of frequency part of record (always 4 bytes)
# P["entrylen"] - length of total part of record
# P["n"]        - number of records
# P["sort"]     - field name sorted by (word or frequency)
# P["stats"]    - corpus statistics
#
# Format of record:
#
# 2 bytes              - LW - actual length of word within field
# P["wlen"] bytes      - LW bytes of word (W) + P["wlen"]-LW bytes of padding
# P["flen"] (4) bytes  - frequency as network byte order long
#

class CorrectHorseBatteryStaple::Corpus::Isam < CorrectHorseBatteryStaple::Corpus::Base
  include CorrectHorseBatteryStaple::Backend::Isam
  include CorrectHorseBatteryStaple::Memoize

  INITIAL_PRELUDE_LENGTH = 4096

  def initialize(filename, stats = nil)
    super
    @filename = filename
    @file = CorrectHorseBatteryStaple::Util.open_binary(filename, "r")
    parse_prelude
  end

  # factory-ish constructor
  def self.read(filename)
    self.new filename
  end

  ## optimized pick - does NOT support :filter, though
  def pick(count, options = {})
    # incompat check
    raise NotImplementedError, "ISAM does not support :filter option" if options[:filter]

    # options parsing
    string         = record_percentile_range_read(options[:percentile] || (0..100))
    range_size     = string.length / @entry_length
    max_iterations = [options[:max_iterations] || 1000, count*10].max

    if range_size < count
      raise ArgumentError, "Percentile range contains fewer words than requested count: p=#{options[:percentile].inspect}, l=#{string.length}, el=#{@entry_length}, range_size = #{range_size}"
    end

    # the real work
    result         = _pick(string, count, options[:word_length], max_iterations)

    # validate that we succeeded
    raise "Cannot find #{count} words matching criteria" if result.length < count

    result
  end

  def _pick(string, count, length_range, max_iterations)
    result = []
    iterations = 0

    # don't bother reading already read words
    skip_cache = Set.new
    range_size = string.length / @entry_length

    # don't cons!
    entry = CorrectHorseBatteryStaple::Word.new :word => ""
    while result.length < count && iterations < max_iterations
      i = random_number(range_size)
      unless skip_cache.include? i
        pr = parse_record(string, i, entry, length_range)
        if pr
          result << pr.dup
        else
          skip_cache << i
        end
      end
      iterations += 1
    end
    result
  end

end
