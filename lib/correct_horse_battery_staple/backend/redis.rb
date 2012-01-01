require 'redis'
require 'securerandom'

module CorrectHorseBatteryStaple::Backend::Redis

  def self.included(base)
    base.extend ClassMethods
    base.send :include, InstanceMethods
  end

  
  LENGTH_SET_KEY_NAME      = "wordlength"
  PERCENTILE_SET_KEY_NAME  = "percentile"

  
  module ClassMethods
  end

  module InstanceMethods
    def add_word(w)
      percentile = [0, w.percentile].max

      @db.zadd(@length_key, w.word.length, w.word)
      @db.zadd(@percentile_key, percentile, w.word)
    end

    def save_stats(stats)
      # stats.each do |key, value|
      #   @db.execute "insert into stats (name, value) values (?, ?)", key.to_s, value
      # end
    end

    def create_database
      db.del @length_key, @percentile_key
    end

    def open_database
      @length_key            = make_key(LENGTH_SET_KEY_NAME)
      @percentile_key        = make_key(PERCENTILE_SET_KEY_NAME)
      @db = ::Redis.new(:host => options[:host], :port => options[:port])
    end

    def db
      @db || open_database
    end

    def close_database
    end

    def make_key(name)
      "chbs_" + "dbname" + "_" + name
    end

    def gensym_temp
      @_gensym_id ||= 0
      make_key("TEMP_" + Process.pid + (@gensym_id += 1))
    end
  end
end

