
class CorrectHorseBatteryStaple::Corpus
  def self.read(filename, clazz=nil)
    clazz ||=
      case CorrectHorseBatteryStaple::Corpus.format_for(filename)
      # when 'kdtree' then CorrectHorseBatteryStaple::Corpus::KDTree
      when 'isam' then CorrectHorseBatteryStaple::Corpus::Isam
      when 'kdtree', 'isamkd' then CorrectHorseBatteryStaple::Corpus::IsamKD
      when 'sqlite' then CorrectHorseBatteryStaple::Corpus::Sqlite
      when 'redis2' then CorrectHorseBatteryStaple::Corpus::Redis2
      when 'redis' then CorrectHorseBatteryStaple::Corpus::Redis
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
  autoload :IsamKD,     'correct_horse_battery_staple/corpus/isam_kd'
  autoload :Sqlite,     'correct_horse_battery_staple/corpus/sqlite'
  autoload :Redis,      'correct_horse_battery_staple/corpus/redis'
  autoload :Redis2,     'correct_horse_battery_staple/corpus/redis2'
  # autoload :KDTree,     'correct_horse_battery_staple/corpus/kdtree'
end

