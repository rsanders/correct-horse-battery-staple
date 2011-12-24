class CorrectHorseBatteryStaple::Parser

  class WStruct < Struct.new(:word, :frequency, :rank, :dispersion)
    include Comparable
    def <=>(other)
      self.frequency <=> other.frequency
    end
  end

end
