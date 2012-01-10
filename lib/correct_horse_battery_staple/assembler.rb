require 'bigdecimal'
require 'json'

class CorrectHorseBatteryStaple::Assembler
  include CorrectHorseBatteryStaple::Common

  attr_accessor :words

  VALID_INITIAL_CHARS = ([*'a'..'z']).map {|ls| ls[0]}

  def initialize(parser = nil)
    @parser = (parser || CorrectHorseBatteryStaple::Parser::Regex.new(:wiktionary))
  end

  def read(urls)
    self.words =
      urls.map do |url|
        @parser.parse open(url)
      end.reduce(:+).
          select {|wstruct| VALID_INITIAL_CHARS.include?(wstruct.word[0]) }.
      # we take a round-trip through a Hash to weed out dupes
          inject({}) {|h, wstruct|  h[wstruct.word] = wstruct; h }.
          values.
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
    end
  end

end
