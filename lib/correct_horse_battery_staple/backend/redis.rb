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

    def load_stats
      load_stats_from_hash Hash[db.hgetall(@stats_key).map {|k,v| [k, v.to_f]}]
    end

    def save_stats(stats)
      db.hmset @stats_key, *stats.to_a.flatten
    end

    def create_database
      db.del @length_key, @percentile_key, @frequency_key, @stats_key
    end

    def open_database
      @db ||= begin
                @length_key            = make_key("length_zset")
                @percentile_key        = make_key("percentile_zset")
                @freqency_key          = make_key("frequency_zset")
                @stats_key             = make_key("stats_hash")
                ::Redis.new(:host => options[:host], :port => options[:port])
              end
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

