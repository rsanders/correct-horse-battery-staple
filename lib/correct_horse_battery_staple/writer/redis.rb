require 'redis'
require 'securerandom'

class CorrectHorseBatteryStaple::Writer::Redis < CorrectHorseBatteryStaple::Writer::Base

  include CorrectHorseBatteryStaple::Backend::Redis

  def initialize(dest, options={})
    super
    parse_uri(dest)
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

