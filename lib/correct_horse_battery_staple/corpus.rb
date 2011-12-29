
class CorrectHorseBatteryStaple::Corpus
  def self.read(filename, clazz=nil)
    clazz ||=
      case File.extname(filename)[1..-1]
      when 'isam' then CorrectHorseBatteryStaple::Corpus::Isam
      else CorrectHorseBatteryStaple::Corpus::Serialized
      end

    clazz.read(filename)
  end

  autoload :Base, 'correct_horse_battery_staple/corpus/base'
  autoload :Serialized, 'correct_horse_battery_staple/corpus/serialized'
  autoload :Isam,'correct_horse_battery_staple/corpus/isam'
end

