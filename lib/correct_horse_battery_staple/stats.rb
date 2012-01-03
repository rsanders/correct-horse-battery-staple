require 'ostruct'
require 'json'

class CorrectHorseBatteryStaple::Stats < OpenStruct
  def to_hash
    marshal_dump
  end

  def self.from_hash(hash)
    new.tap do |newobj|
      marshal_load(hash)
    end
  end

  def to_json
    to_hash.to_json
  end

  def self.from_json(json)
    from_hash JSON.parse(json)
  end
end
