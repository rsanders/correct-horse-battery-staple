class CorrectHorseBatteryStaple::Parser

  class WStruct < Struct.new(:word, :frequency, :rank, :dispersion)
    include Comparable
    def <=>(other)
      self.frequency <=> other.frequency
    end

    def to_json(*args)
      to_hash.to_json(*args)
    end

    def to_csv(*args)
      to_hash.to_csv(*args)
    end

    def to_hash
      {:word => word, :frequency => frequency,
       :rank => rank, :dispersion => dispersion}
    end
  end

end

require 'correct_horse_battery_staple/parser/base'
require 'correct_horse_battery_staple/parser/regex'
