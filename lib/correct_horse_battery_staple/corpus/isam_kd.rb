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

class CorrectHorseBatteryStaple::Corpus::IsamKD < CorrectHorseBatteryStaple::Corpus::Base
  include CorrectHorseBatteryStaple::Memoize
  include CorrectHorseBatteryStaple::Backend::IsamKD

  def initialize(filename, stats = nil)
    @filename = filename
    @file = CorrectHorseBatteryStaple::Util.open_binary(filename, "r")
    parse_prelude
    load_index
  end

  def precache(max = -1)
    return if max > -1 && file_size(@file) > max
    @file.seek 0
    @file = StringIO.new @file.read, "r"
  end

  def file_size(file)
    (file.respond_to?(:size) ? file.size : file.stat.size)
  end

  def prelude
    @prelude ||= parse_prelude
  end

  def load_index
    @kdtree ||= load_kdtree
  end
  
end
