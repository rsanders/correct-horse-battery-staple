require 'bigdecimal'
require 'json'

class CorrectHorseBatteryStaple::Assembler
  include CorrectHorseBatteryStaple::Common

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

    self
  end

  def randomize
    self.words.shuffle!
    self
  end

  def limit(count)
    self.words.slice!(count..-1) if self.words.length > count
    self
  end

  def corpus
    @corpus ||= CorrectHorseBatteryStaple::Corpus::Serialized.new(self.words).tap do |corpus|
      corpus.recalculate
      stats              = corpus.stats
      size               = corpus.count
      frequency_mean     = corpus.frequency_mean
      frequency_stddev   = corpus.frequency_stddev
      weighted_size      = corpus.weighted_size
      probability_mean   = corpus.probability_mean
      probability_stddev = corpus.probability_stddev

      corpus.each_with_index do |entry, index|
        entry.rank                      = size - index
        entry.distance                  = (entry.frequency-frequency_mean)/frequency_stddev
        entry.probability               = entry.frequency / weighted_size
        entry.distance_probability      = (entry.probability - probability_mean) / probability_stddev
        entry.percentile                = (index-0.5)/size * 100
      end
    end
  end

end
