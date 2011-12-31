
require 'securerandom'

#
# Generate an N-word passphrase from a corpus
#
class CorrectHorseBatteryStaple::Generator
  include CorrectHorseBatteryStaple::Common

  attr_accessor :word_length, :corpus

  def initialize(corpus, word_length = nil)
    @corpus      = corpus
    if word_length
      @corpus.filter {|entry| word_length.include?(entry.word.to_s.length) }
    end
  end

  def make(count = 4, options = {})
    @corpus.pick(count, options).
      map {|entry| entry.word.downcase }.
      join("-")
  end

  def estimate_entropy(options)
    candidate_count = @corpus.count_candidates(options)
    bits_per = (log(candidate_count) / log(2)).floor
  end

  def words
    @words ||= @corpus.result
  end
end

if __FILE__ == $0
  puts CorrectHorseBatteryStaple::Generator.new(CorrectHorseBatteryStaple.default_corpus, 3..6).
    make((ARGV[0] || 4).to_i)
end
