require 'bigdecimal'
require 'json'

class CorrectHorseBatteryStaple::Assembler

  attr_accessor :freq_mean, :freq_stddev
  attr_accessor :prob_mean, :prob_stddev
  attr_accessor :corpus_size
  attr_accessor :weighted_corpus_size
  attr_accessor :words

  VALID_INITIAL_CHARS = ([*'A'..'Z'] + [*'a'..'z']).map {|ls| ls[0]}

  def initialize(parser = nil)
    @parser = (parser || CorrectHorseBatteryStaple::Parser::Regex.new(:wiktionary))
  end

  def read(urls)
    self.words = 
      urls.map do |url|
        @parser.parse open(url)
      end.reduce(:+).
          select {|wstruct| VALID_INITIAL_CHARS.include?(wstruct.word[0]) }.
          sort
  end

  def process
    self.corpus_size           = words.length

    # assign ranks
    words.each_with_index {|word, i| word.rank = corpus_size-i }

    self.weighted_corpus_size  = frequencies.reduce(BigDecimal.new("0"), :+)

    (self.prob_mean, self.prob_stddev)    = CorrectHorseBatteryStaple::StatisticalArray.new(frequencies.map do |freq|
        (freq/weighted_corpus_size) * 100
      end).mean_and_standard_deviation
    (self.freq_mean, self.freq_stddev)    = frequencies.mean_and_standard_deviation
  end

  def stats
    {:freq_mean => freq_mean, :freq_stddev => freq_stddev,
      :prob_mean => prob_mean, :prob_stddev => prob_stddev,
      :corpus_size => corpus_size,
      :weighted_corpus_size => weighted_corpus_size.to_f}
  end

  def save_as_csv(io)
    io.puts "index,rank,word,frequency,percentile,distance,probability,distance_probability"
    assemble do |w|
      io.puts sprintf("%d,%d,\"%s\",%d,%.4f,%.6f,%.8f,%.8f\n",
        w.index, w.rank, w.word, w.frequency,
        w.percentile, w.distance, w.probability, w.distance_probability)
    end
  end

  def save_as_json(io)
    io.print '{"stats": '
    io.print stats.to_json
    io.print ', "corpus": ['
    i = 0
    assemble do |entry|
      io.puts "," if i >= 1
      io.print(entry.to_json)
      i += 1
    end
    puts "]"
    io.puts "}"
  end

  def assemble
    words.each_with_index do |wstruct, index|
      word            = wstruct.word
      freq            = wstruct.frequency
      distance        = (freq-freq_mean)/freq_stddev
      probability     = freq/weighted_corpus_size
      distance_prob   = (probability - prob_mean) / prob_stddev
      percentile      = (index-0.5)/corpus_size * 100
      yield :index => index,
        :wstruct => wstruct,
        :word => word,
        :rank => wstruct.rank, :frequency => freq,
        :percentile => percentile, :distance => distance,
        :probability => (probability * 100).to_f,
        :distance_probability => distance_prob.to_f
    end
  end

  protected

  def frequencies
    @frequencies ||= CorrectHorseBatteryStaple::StatisticalArray.new(words.map {|pair| pair.frequency })
  end

end
