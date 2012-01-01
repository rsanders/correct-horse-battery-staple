require 'redis'
require 'securerandom'

class CorrectHorseBatteryStaple::Writer::Redis < CorrectHorseBatteryStaple::Writer::Base

  include CorrectHorseBatteryStaple::Backend::Redis

  def initialize(dest, options={})
    (dbname, host, port)   = dest.split(':')
    options[:dbname]     ||= (dbname || "chbs")
    options[:host]       ||= (host   || "127.0.0.1")
    options[:port]       ||= (port  || 6379).to_i

    super
  end


  def write_corpus(corpus)
    create_database
    open_database

    db.multi do
      save_entries(corpus)
      save_stats(corpus.stats)
    end
  rescue
    logger.error "error in Redis write_corpus: #{$!.inspect}"
    raise
  ensure
    close_database
  end

  protected

  def save_entries(corpus)
    size = corpus.size
    corpus.each_with_index do |w, index|
      add_word(w)
    end
  ensure
  end

end

