require 'bigdecimal'
require 'sqlite3'

class CorrectHorseBatteryStaple::Corpus::Sqlite < CorrectHorseBatteryStaple::Corpus::Base
  def initialize(file)
    @db = SQLite3::Database.open file
    load_stats
  end

  def self.read(file)
    self.new file
  end

  ## some core Enumerable building blocks

  def each(&block)
    entries.each &block
  end

  def size
    @size ||= @db.execute("select count(*) from entries").first.first
  end

  def entries
    @entries ||= table
  end

  def sorted_entries
    entries
  end


  ## optimized pick - does NOT support :filter, though

  def pick(count, options = {})
    # incompat check
    raise NotImplementedError, "SQLite does not support :filter option" if options[:filter]

    statement = "select #{COLUMNS.join(", ")} from entries "
    params = []
    wheres = []
    if options[:word_length]
      wheres << "  wordlength >= ? and wordlength <= ? "
      params += [options[:word_length].first, options[:word_length].last]
    end
    if options[:percentile]
      wheres << "  percentile >= ? and percentile <= ? "
      params += [options[:percentile].first, options[:percentile].last]
    end
    statement = statement + (wheres.empty? ? "" : " WHERE " + wheres.join(" AND ")) +
      " order by RANDOM() limit #{count}"

    rows = @db.execute(statement, *params)
    result = rows.map { |row| word_from_row(row) }

    # validate that we succeeded
    raise "Cannot find #{count} words matching criteria" if result.count < count

    result
  end

  protected

  COLUMNS = %w[word frequency idx rank percentile]

  def table
    @db.execute("select #{COLUMNS.join(", ")} from entries order by frequency").map do |row|
      word_from_row(row)
    end
  end

  def word_from_row(row)
    CorrectHorseBatteryStaple::Word.new(:word => row[0], :frequency => row[1],
                                        :index => row[2], :rank => row[3], :percentile => row[4])
  end

  def load_stats
    rows = @db.execute "select name, value from stats"
    load_stats_from_hash(rows.reduce({}) {|m, (key, val)| m.merge(key => val.to_f)})
  end
end
