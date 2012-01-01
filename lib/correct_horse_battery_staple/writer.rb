class CorrectHorseBatteryStaple::Writer
  def self.make_writer(dest, fformat, options = {})
    fformat ||= CorrectHorseBatteryStaple::Corpus.format_for(dest)
    raise ArgumentError, "Cannot determine file format for #{dest}" if !fformat || fformat.empty?

    clazz = const_get(fformat.downcase.capitalize)
    clazz.new(dest, options)
  end

  def self.write(corpus, dest, fformat, options = {})
    writer = self.make_writer(dest, fformat, options)
    begin
      writer.write_corpus(corpus)
    ensure
      writer && writer.close
    end
  end

  autoload :Base,     "correct_horse_battery_staple/writer/base"
  autoload :File,     "correct_horse_battery_staple/writer/file"
  autoload :Json,     "correct_horse_battery_staple/writer/json"
  autoload :Csv,      "correct_horse_battery_staple/writer/csv"
  autoload :Isam,     "correct_horse_battery_staple/writer/isam"
  autoload :Marshal,  "correct_horse_battery_staple/writer/marshal"
  autoload :Sqlite,   "correct_horse_battery_staple/writer/sqlite"
  autoload :Redis,    "correct_horse_battery_staple/writer/redis"
end
