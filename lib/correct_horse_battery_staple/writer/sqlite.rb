require 'sqlite3'
require 'securerandom'

class CorrectHorseBatteryStaple::Writer::Sqlite < CorrectHorseBatteryStaple::Writer::Base

  def initialize(dest, options={})
    super
  end

  # select * from entries where percentile < 30 and percentile > 20 and wordlength >= 9 and wordlength <= 12  order by RANDOM() limit 6;
  def write_corpus(corpus)
    create_database

    @db.transaction do
      save_entries(@db, corpus)
      save_stats(@db, corpus.stats)
    end

  rescue
    logger.error "error in SQLite write_corpus: #{$!.inspect}"
    raise
  ensure
    close_database
  end

  protected

  def save_entries(db, corpus)
    statement = db.prepare("insert into entries " +
                           "(word, wordlength, frequency, idx, rank, percentile, randunit) " +
                           "values (?, ?, ?, ?, ?, ?, ?)")
    rstmt = db.prepare("insert into index3d (id, minP, maxP, minL, maxL, minR, maxR) " +
                       "values (?, ?, ?, ?, ?, ?, ?)")

    size = corpus.size
    corpus.each_with_index do |w, index|
      percentile = [0, w.percentile].max.round
      rndnum = Random.rand
      res = statement.execute(w.word, w.word.length, w.frequency.to_i,
                              index+1, size-index, percentile,
                              rndnum)
      row_id = @db.last_insert_row_id
      rstmt.execute(row_id,
                    percentile, percentile,
                    w.word.length, w.word.length,
                    rndnum, rndnum)
    end
  ensure
    statement.close rescue nil
    rstmt.close rescue nil
  end

  def save_stats(db, stats)
    stats.each do |key, value|
      @db.execute "insert into stats (name, value) values (?, ?)", key.to_s, value
    end
  end

  def path_for(dest)
    dest.respond_to?(:path) ? dest.path : dest
  end

  def create_database
    @db = SQLite3::Database.new path_for(dest)

    # Create a database
    rows = @db.execute <<-SQL
      create table entries (
        id integer primary key,
        word varchar(32),
        wordlength integer,
        frequency integer,
        idx integer,
        rank integer,
        percentile integer,
        randunit double
      );
     SQL

    @db.execute <<-VTSQL
        CREATE VIRTUAL TABLE index3d USING rtree(
           id,              -- Integer primary key
           minP, maxP,      -- Minimum and maximum percentile
           minL, maxL,      -- Minimum and maximum percentile
           minR, maxR       -- Min/max Randomly assigned #
        );
     VTSQL

    ['create index freqidx on entries (frequency, wordlength)',
     'create index percentileidx on entries (percentile, wordlength)',
     'create index wordidx on entries (word)',
     'create index randidx on entries (randunit, percentile)'
    ].each do |stmt|
      @db.execute stmt
    end

    @db.execute <<-SQL
      create table stats (
        name varchar(60),
        value double
      );
    SQL
  end

  def close_database
    if @db
      @db.execute 'vacuum'
      @db.execute 'analyze'
      @db.close
    end
  end

end

Random.srand(SecureRandom.random_number)
