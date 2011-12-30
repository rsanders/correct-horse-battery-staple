require 'sqlite3'

class CorrectHorseBatteryStaple::Writer::Sqlite < CorrectHorseBatteryStaple::Writer::Base

  def initialize(dest, options={})
    super
  end
  # select * from entries where percentile < 30 and percentile > 20 and wordlength >= 9 and wordlength <= 12  order by RANDOM() limit 6;
  def write_corpus(corpus)
    create_database

    statement = @db.prepare("insert into entries (word, wordlength, frequency, idx, rank, percentile) values (?, ?, ?, ?, ?, ?)")
    size = corpus.size
    corpus.each_with_index do |w, index|
      res = statement.execute(w.word, w.word.length, w.frequency.to_i, index+1,
                              size-index, [0, w.percentile].max)
    end

    corpus.stats.each do |key, value| 
      @db.execute "insert into stats (name, value) values (?, ?)", key.to_s, value
    end
  rescue
    STDERR.puts "error in write_corpus: #{$!.inspect}"
  ensure
    statement.close
    close_database
  end

  protected

  def create_database
    @db = SQLite3::Database.new dest.path

    # Create a database
    rows = @db.execute <<-SQL
      create table entries (
        word varchar(30),
        wordlength int,
        frequency int,
        idx int,
        rank int,
        percentile double
      );
     SQL

    ['create index freqidx on entries (frequency, wordlength)',
     'create index percentileidx on entries (percentile, wordlength)',
     'create index wordidx on entries (word)'].each do |stmt|
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
    @db.execute 'vacuum'
    @db.execute 'analyze'
    @db.close
  end

end
