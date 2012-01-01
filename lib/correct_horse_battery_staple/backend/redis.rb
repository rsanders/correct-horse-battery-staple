require 'redis'
require 'securerandom'

module CorrectHorseBatteryStaple::Backend::Redis

  def self.included(base)
    base.extend ClassMethods
    base.send :include, InstanceMethods
  end

  module ClassMethods
  end

  module InstanceMethods
    def parse_uri(dest)
      (dbname, host, port)   = dest.split(':')
      options[:dbname]     ||= (dbname || "chbs")
      options[:host]       ||= (host   || "127.0.0.1")
      options[:port]       ||= (port  || 6379).to_i
    end

    def add_word(w)
      percentile = [0, w.percentile].max

      @db.zadd(@length_key, w.word.length, w.word)
      @db.zadd(@percentile_key, percentile, w.word)
      @db.zadd(@frequency_key, w.frequency, w.word)
    end

    def save_stats(stats)
      # stats.each do |key, value|
      #   @db.execute "insert into stats (name, value) values (?, ?)", key.to_s, value
      # end
    end

    def create_database
      db.del @length_key, @percentile_key, @frequency_key
    end

    def open_database
      @length_key            = make_key("length_zset")
      @percentile_key        = make_key("percentile_zset")
      @freqency_key          = make_key("frequency_zset")
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

