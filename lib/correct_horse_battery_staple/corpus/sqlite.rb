require 'bigdecimal'
require 'sqlite3'

class CorrectHorseBatteryStaple::Corpus::Sqlite < CorrectHorseBatteryStaple::Corpus::Base
  MAX_ITERATIONS = 1000

  def initialize(file)
    @db = SQLite3::Database.open file
    @statements = []
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
    base = "select id from index3d "
    wheres = []
    params = []

    wheres << "minR >= ? and maxR <= ?"
    rnd = random_number
    offset = 0.0
    if rnd > 0.8
      offset = 0.8-rnd
    elsif rnd < 0.2
      offset = 0.2-rnd
    end
    params += [rnd - 0.20 + offset, rnd + 0.20 + offset]

    if options[:word_length]
      wheres << "  minL >= ? and maxL <= ? "
      params += [options[:word_length].first, options[:word_length].last]
    end
    if options[:percentile]
      wheres << "  minP >= ? and maxP <= ? "
      params += [options[:percentile].first, options[:percentile].last]
    end
    statement = [base,
                 (wheres.empty? ? "" : " WHERE " + wheres.join(" AND ")),
                 "limit ?"].join(" ")
    params += [[count,250].max]

    query = prepare(statement)
    ids = query.execute!(*params).shuffle[0...count].map {|r| r[0]}

    if ids and !ids.empty?
      result = get_words_for_ids(ids)
    else
      result = []
    end

    # validate that we succeeded
    raise "Cannot find #{count} words matching criteria" if result.length < count

    result
  end

  def get_words_for_ids(ids)
    ids = Array(ids)
    rows = @db.execute("select #{COLUMNS.join(", ")} from entries where id in (#{ids.join(',')})")

    words = []
    ids.each do |id|
      words << rows.find {|r| r[0] == id }
    end
    words.map {|row| word_from_row(row)}
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
                 # "order by RANDOM()",
                 "limit ?"].join(" ")
    params << [count, 250].max
    query = prepare(statement)
    result = query.execute!(*params).
      shuffle[0...count].
      map { |row| word_from_row(row) }

    # validate that we succeeded
    raise "Cannot find #{count} words matching criteria" if result.length < count

    result
  end

  def pick_standard2(count, options = {})
    statement = "select id from entries "
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
                 # "order by RANDOM()",
                 "limit ?"].join(" ")
    params << [count, 250].max
    query = prepare(statement)
    ids = query.execute!(*params).
      shuffle[0...count].map {|r| r[0]}

    result = get_words_for_ids(ids)

    # validate that we succeeded
    raise "Cannot find #{count} words matching criteria" if result.length < count

    result
  end


  # discrete method
  def pick_discrete(count, options = {})

    p_range = options[:percentile] or 0..100
    l_range = options[:word_length] or 4..12

    result = []
    iterations = 0
    while (iterations < 4 || result.length < count) && iterations < MAX_ITERATIONS
      percentile  = random_in_range(p_range)
      length      = random_in_range(l_range)
      result     += _pick_discrete_n(percentile, length, 1)
      iterations += 1
    end

    # validate that we succeeded
    raise "Cannot find #{count} words matching criteria" if result.length < count

    result.shuffle[0...count].map {|row| word_from_row(row)}
  end

  def prepare(statement)
    res = @db.prepare(statement)
    @statements << res
    res
  end
  memoize :prepare

  def _pick_discrete_n(percentile, length, count = 1)
    statement = prepare "select #{COLUMNS.join(", ")} from entries where " +
      " percentile = ? and wordlength = ? and randunit < ? limit ?"

    statement.execute!(percentile, length, random_number, count)
  end


  # discrete method
  def pick_discrete2(count, options = {})

    p_range = options[:percentile] or 0..100
    l_range = options[:word_length] or 4..12

    ids = []
    iterations = 0
    while (iterations < 3 || ids.length < count) && iterations < MAX_ITERATIONS
      percentile  = random_in_range(p_range)
      length      = random_in_range(l_range)
      ids         = ids.concat(_pick_discrete_n_ids(percentile, length, 25)).uniq
      iterations += 1
    end

    ids = ids.shuffle[0...count].map {|r| r[0] }
    result = get_words_for_ids(ids)

    # validate that we succeeded
    raise "Cannot find #{count} words matching criteria" if result.length < count
    result
  end

  def prepare(statement)
    res = @db.prepare(statement)
    @statements << res
    res
  end
  memoize :prepare

  def _pick_discrete_n_ids(percentile, length, count = 1)
    statement = prepare "select id from entries where " +
      " percentile = ? and wordlength = ? and randunit > ? limit ?"

    statement.execute!(percentile, length, random_number, count)
  end



  def close
    @statements.each { |x| x.close }
    super
  end

  protected

  COLUMNS = %w[id word frequency idx rank percentile]

  def table
    @db.execute("select #{COLUMNS.join(", ")} from entries order by frequency").map do |row|
      word_from_row(row)
    end
  end

  def word_from_row(row)
    CorrectHorseBatteryStaple::Word.new(:word => row[1], :frequency => row[2],
                                        :index => row[3], :rank => row[4],
                                        :percentile => row[5])
  end

  def load_stats
    rows = @db.execute "select name, value from stats"
    load_stats_from_hash(rows.reduce({}) {|m, (key, val)| m.merge(key => val.to_f)})
  end
end
