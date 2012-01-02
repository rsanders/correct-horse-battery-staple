require 'redis'
if ! Object.const_defined?("JRUBY_VERSION")
 require 'redis/connection/hiredis'
end
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
      (dbname, host, port)   = dest.gsub(/\.redis[0-9]?/, '').split(':')
      options[:dbname]     ||= (dbname || "chbs")
      options[:host]       ||= (host   || "127.0.0.1")
      options[:port]       ||= (port  || 6379).to_i
    end

    def add_word(w, wid=nil)
      percentile = [0, w.percentile].max

      wid = get_new_word_id if wid.nil?

      db.zadd(@words_key, wid, w.word)
      db.zadd(@length_key, w.word.length, wid)
      db.zadd(@percentile_key, percentile, wid)
      db.zadd(@frequency_key, w.frequency, wid)
    end

    #
    # Note that this does NOT work inside a multi/exec
    #
    def get_new_word_id
      db.incr(@id_key)
    end

    def get_word_by_id(wid)
      db.zrangebyscore(@words_key, wid, wid, :limit => [0,1])[0] rescue nil
    end

    def load_stats
      load_stats_from_hash Hash[db.hgetall(@stats_key).map {|k,v| [k, v.to_f]}]
    end

    def save_stats(stats)
      db.hmset @stats_key, *stats.to_a.flatten
    end

    def create_database
      db.del(@length_key, @percentile_key, @frequency_key, @stats_key,
             @words_key, @id_key)
    end

    def open_database
      @db ||= begin
                @length_key            = make_key("length_zset")
                @percentile_key        = make_key("percentile_zset")
                @frequency_key         = make_key("frequency_zset")
                @stats_key             = make_key("stats_hash")
                @words_key             = make_key("words_zset")
                @id_key                = make_key("word_id_counter")
                ::Redis.new(:host => options[:host], :port => options[:port])
              end
    end

    def db
      @db || open_database
    end

    def close_database
    end

    def make_key(name)
      "chbs_#{options[:dbname]}_#{name}"
    end

    def gensym_temp
      @_gensym_id ||= 0
      make_key("TEMP_" + Process.pid + (@gensym_id += 1))
    end
  end
end

