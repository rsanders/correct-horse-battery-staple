class CorrectHorseBatteryStaple::Parser

  class WStruct < Struct.new(:word, :frequency, :rank, :dispersion)
    include Comparable
    def <=>(other)
      self.frequency <=> other.frequency
    end
  end

end

require 'correct_horse_battery_staple/parser/base'
require 'correct_horse_battery_staple/parser/regex'
