class CorrectHorseBatteryStaple::Word 
  attr_accessor :word, :frequency, :rank, :dispersion, :index
  attr_accessor :percentile, :distance
  attr_accessor :probability, :distance_probability

  include Comparable

  def initialize(value_map = {})
    raise ArgumentError, "Must supply at least :word" unless value_map[:word] || value_map["word"]

    update_from_hash(value_map)
  end

  def <=>(other)
    self.frequency <=> other.frequency
  end

  def to_json(*args)
    to_hash.to_json(*args)
  end

  def self.from_json(json)
    self.new.update_from_hash(JSON.read(json))
  end

  def to_s
    self.word
  end

  def inspect
    "CRBS::Word(#{to_hash.inspect})"
  end
  
  def to_hash
    {}.tap do |hash|
      instance_variables.each do |key, val|
        hash[key.to_s[1..-1]] = val
      end
    end
  end

  def update_from_hash(hash)
    hash.each do |key, val|
      next if key.to_s == "wstruct"
      send "#{key}=", val
    end
    self
  end

  def [](attr)
    send(attr.to_s)
  end

  def []=(attr, value)
    send("#{attr}=", value)
  end
end
