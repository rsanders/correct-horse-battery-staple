class CorrectHorseBatteryStaple::Word 
  attr_accessor :word, :frequency, :rank, :dispersion, :index
  attr_accessor :percentile, :distance
  attr_accessor :probability, :distance_probability

  include Comparable

  def initialize(value_map = {})
    raise ArgumentError, "Must supply at least :word" unless value_map[:word] || value_map["word"]

    case value_map
      when Hash then     update_from_hash(value_map)
      when CorrectHorseBatteryStaple::Word then update_from_hash(value_map.to_hash)
      else raise "What? #{value_map}"
    end
  end

  def <=>(other)
    self.frequency <=> other.frequency
  end

  def to_json(*args)
    to_hash.to_json(*args)
  end

  def to_s
    self.word
  end

  def inspect
    "CRBS::Word(#{self.to_hash.inspect})"
  end

  def to_hash
    instance_variables.reduce({}) do |hash, key|
      hash[key.to_s[1..-1]] = instance_variable_get(key)
      hash
    end
  end

  def update_from_hash(hash)
    hash.each do |key, val|
      self[key] = val unless key.to_s == "wstruct"
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
