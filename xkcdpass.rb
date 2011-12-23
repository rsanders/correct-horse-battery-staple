#!/usr/bin/env ruby

require 'securerandom'

#
# Generate 
#
class WordPasswordMaker
  def initialize(word_length, file=nil)
    @word_length = word_length
    @corpus = file || "/usr/share/dict/words"
  end

  def make(count=4)
    words.
      values_at(
        *count.times.map {  SecureRandom.random_number(words.length) }
      ).
      map { |word| word.chomp.downcase }.
      join("-")
  end

  def words
    @words ||= File.readlines(@corpus).
      # exclude newline from length
      select {|word| @word_length.include?(word.length-1) }
  end
end

if __FILE__ == $0
  puts WordPasswordMaker.new(3..6).
    make((ARGV[0] || 4).to_i)
end
