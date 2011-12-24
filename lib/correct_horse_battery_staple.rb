
module CorrectHorseBatteryStaple
  VERSION = '0.1.0'

  DEFAULT_CORPUS_NAME = "wiktionary"

  def self.default_corpus
    self.load_corpus DEFAULT_CORPUS_NAME
  end

  def self.load_corpus(corpus_name)
    CorrectHorseBatteryStaple::Corpus.read_csv File.join(self.corpus_directory, "#{corpus_name}.csv")
  end

  def self.generate(length = 4)
    CorrectHorseBatteryStaple::Generator.new(self.load_corpus(DEFAULT_CORPUS_NAME)).make(length)
  end

  protected

  def self.corpus_directory
    File.join(File.dirname(__FILE__), "../corpus")
  end

end

require 'correct_horse_battery_staple/generator'
require 'correct_horse_battery_staple/corpus'
require 'correct_horse_battery_staple/parser'
require 'correct_horse_battery_staple/statistical_array'

if __FILE__ == $0
  puts CorrectHorseBatteryStaple.generate((ARGV[0] || 4).to_i)
end
