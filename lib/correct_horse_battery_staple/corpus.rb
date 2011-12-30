
class CorrectHorseBatteryStaple::Corpus
  def self.read(filename, clazz=nil)
    clazz ||=
      case CorrectHorseBatteryStaple::Corpus.format_for(filename)
      when 'isam' then CorrectHorseBatteryStaple::Corpus::Isam
      when 'sqlite' then CorrectHorseBatteryStaple::Corpus::Sqlite
      else CorrectHorseBatteryStaple::Corpus::Serialized
      end

    clazz.read(filename)
  end

  def self.format_for(spec, defval = nil)
    File.extname(spec)[1..-1].downcase || defval
  rescue
    defval
  end

  autoload :Base,       'correct_horse_battery_staple/corpus/base'
  autoload :Serialized, 'correct_horse_battery_staple/corpus/serialized'
  autoload :Isam,       'correct_horse_battery_staple/corpus/isam'
  autoload :Sqlite,     'correct_horse_battery_staple/corpus/sqlite'
end

