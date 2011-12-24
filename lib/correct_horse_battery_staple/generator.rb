#!/usr/bin/env ruby

require 'securerandom'

#
# Generate an N-word passphrase from a corpus
#
class CorrectHorseBatteryStaple::Generator
  VERSION = '0.1.0'

  attr_accessor :word_length, :corpus

  def initialize(corpus, word_length = 3..6)
    @corpus      = corpus
    @word_length = word_length
  end

  def make(count=4)
    words.
      values_at(
        *count.times.map {  SecureRandom.random_number(words.length) }
      ).
      map { |word| word.downcase }.
      join("-")
  end

  def words
    @words ||= @corpus.
      filter {|entry|  @word_length.include?(entry[:word].to_s.length)
    }.
    result.map {|e| e[:word]}
  end
end

if __FILE__ == $0
  puts CorrectHorseBatteryStaple::Generator.new(CorrectHorseBatteryStaple.default_corpus, 3..6).
    make((ARGV[0] || 4).to_i)
end
