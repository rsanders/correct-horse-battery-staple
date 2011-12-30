require 'bigdecimal'
require 'sqlite3'

class CorrectHorseBatteryStaple::Corpus::Sqlite < CorrectHorseBatteryStaple::Corpus::Base
  def initialize(file)
    @db = SQLite3::Database.open file
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
end
