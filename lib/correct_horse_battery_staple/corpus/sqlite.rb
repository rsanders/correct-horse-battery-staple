require 'bigdecimal'
require 'sqlite3'

class CorrectHorseBatteryStaple::Corpus::Sqlite < CorrectHorseBatteryStaple::Corpus::Base
  MAX_ITERATIONS = 1000

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



  ## our own collection operations

  def entries
    @entries ||= table
  end

  def sorted_entries
    entries
  end

  def frequencies
    @frequencies ||= @db.execute("select frequency from entries").map {|x| x.first}
  end


  ## optimized pick variants - they do NOT support :filter, though

  def pick(count, options = {})
    # incompat check
    raise NotImplementedError, "SQLite does not support :filter option" if options[:filter]

    strategy = options.delete(:strategy) || ENV['pick_strategy'] || "discrete"
    send("pick_#{strategy}", count, options)
  end

  def pick_rtree(count, options = {})
    statement = "select id from index3d "
    wheres = []
    params = []

    wheres << "minR >= ? and maxR <= ?"
    rnd = SecureRandom.random_number
    # params += [SecureRandom.random_number, SecureRandom.random_number].sort
    params += [rnd - 0.20, rnd + 0.20]

    if options[:word_length]
      wheres << "  minL >= ? and maxL <= ? "
      params += [options[:word_length].first, options[:word_length].last]
    end
    if options[:percentile]
      wheres << "  minP >= ? and maxP <= ? "
      params += [options[:percentile].first, options[:percentile].last]
    end
    statement = [statement,
                 (wheres.empty? ? "" : " WHERE " + wheres.join(" AND ")),
                 "order by (minR - #{rand})",
                 "limit #{count}"].join(" ")

    ids = @db.execute(statement, *params).map {|r| r[0]}

    if ids and !ids.empty?
      rows = @db.execute("select #{COLUMNS.join(", ")} from entries where id IN (#{ids.join(",")}) ")
      result = rows.map { |row| word_from_row(row) }
    else
      result = []
    end

    # validate that we succeeded
    raise "Cannot find #{count} words matching criteria" if result.length < count

    result
  end

  def pick_standard(count, options = {})
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
    statement = [statement,
                 (wheres.empty? ? "" : " WHERE " + wheres.join(" AND ")),
                 "order by RANDOM()",
                 "limit #{count}"].join(" ")

    rows = @db.execute(statement, *params)
    result = rows.map { |row| word_from_row(row) }

    # validate that we succeeded
    raise "Cannot find #{count} words matching criteria" if result.length < count

    result
  end



  def random_in_range(range)
    range.first + SecureRandom.random_number(range_count(range))
  end

  # discrete method
  def pick_discrete(count, options = {})

    p_range = options[:percentile] or 0..100
    l_range = options[:word_length] or 4..12

    result = []
    iterations = 0
    while (iterations < count || result.length < count) && iterations < MAX_ITERATIONS
      percentile  = random_in_range(p_range)
      length      = random_in_range(l_range)
      result     += _pick_discrete_n(percentile, length, 1)
      iterations += 1
    end

    # validate that we succeeded
    raise "Cannot find #{count} words matching criteria" if result.length < count

    result.shuffle[0..count].map {|row| word_from_row(row)}
  end

  def _pick_discrete_n(percentile, length, count = 1)
    statement = "select #{COLUMNS.join(", ")} from entries where " +
      " percentile = ? and wordlength = ? and randunit < ? limit #{count}"

    @db.execute(statement, percentile, length, SecureRandom.random_number)
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
