class CorrectHorseBatteryStaple::Word
  # text of word
  attr_accessor :word

  # frequency is the total count of the word in corpus
  attr_accessor :frequency

  # rank is the word position when sorted by frequency in entire corpus
  # index is the index of the word in this (sub)corpus
  attr_accessor :rank, :index

  # dispersion is Juilland dispersion, the % of texts containing the
  # word. texts is the # of texts containing the word.
  attr_accessor :dispersion

  # texts is the # of texts containing the word. this is not available
  # for many frequency lists.
  attr_accessor :texts

  ## statistical measure of word position in sorted frequency list

  # in which percentile does the word appear. this can be calculated
  # from the array of words so is somewhat redundant here
  attr_accessor :percentile

  # this word's frequency's distance from mean frequency in stddevs;
  # signed.
  attr_accessor :distance

  # probability is the chance of any given word in a text composed
  # of the sum of (word*frequency) in the corpus being this word.
  attr_accessor :probability

  # distance_probability is the distance of this word's probability
  # from the mean in stddev
  attr_accessor :distance_probability

  include Comparable

  def initialize(value_map = {})
    raise ArgumentError, "Must supply at least :word" unless value_map[:word] || value_map["word"]

    # phasing this out
    self.index = -1

    case value_map
      when Hash then update_from_hash(value_map)
      when CorrectHorseBatteryStaple::Word then update_from_hash(value_map.to_hash)
      else raise "Can't initialize Word from #{value_map.inspect}"
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
    "CHBS::Word(#{self.to_hash.inspect})"
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



  def eql?(other)
    self.word == other.word
  end

  def ==(other)
    self.word == other.word
  end
end
