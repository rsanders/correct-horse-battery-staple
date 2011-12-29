require 'logger'

module CorrectHorseBatteryStaple
  VERSION = '0.2.0'

  DEFAULT_CORPUS_NAME = "tvscripts"

  SUPPORTED_FORMATS = %w[isam marshal json csv]

  class << self
    attr_accessor :logger
  end
  self.logger = Logger.new(STDERR)

  def self.default_corpus
    self.load_corpus DEFAULT_CORPUS_NAME
  end

  def self.corpus_search_directories
    [self.corpus_directory]
  end

  def self.corpus_list
    self.corpus_search_directories.map do |dir|
      files = Dir[File.join(dir, "*.{#{SUPPORTED_FORMATS.join(',')}}")].
        map {|file| File.basename(file, File.extname(file)) }
    end.flatten.sort.uniq
  end

  def self.find_corpus(corpus_name, formats = SUPPORTED_FORMATS)
    formats.each do |fmt|
      fname = "#{corpus_name}.#{fmt}"
      self.corpus_search_directories.each do |dir|
        path = File.join(dir, fname)
        return path if File.exist?(path)
      end
    end
    nil
  end

  def self.load_corpus(corpus_name, formats = nil)
    formats = Array(formats || SUPPORTED_FORMATS)
    filename = corpus_name.match(/[.?]/) ? corpus_name :
      self.find_corpus(corpus_name, formats)
    unless filename && File.exist?(filename)
      raise ArgumentError, "Cannot find corpus #{corpus_name}"
    end

    CorrectHorseBatteryStaple::Corpus.read filename
  end

  def self.generate(length = 4)
    CorrectHorseBatteryStaple::Generator.new(self.default_corpus).make(length)
  end

  protected

  def self.corpus_directory
    File.join(File.dirname(__FILE__), "../corpus")
  end

  module Common
    def logger
      CorrectHorseBatteryStaple.logger
    end
  end

  autoload :Word, 'correct_horse_battery_staple/word'
  autoload :Generator, 'correct_horse_battery_staple/generator'
  autoload :Corpus, 'correct_horse_battery_staple/corpus'
  autoload :Parser, 'correct_horse_battery_staple/parser'
  autoload :StatisticalArray, 'correct_horse_battery_staple/statistical_array'
  autoload :RangeParser, 'correct_horse_battery_staple/range_parser'
  autoload :Writer, 'correct_horse_battery_staple/writer'
end


if __FILE__ == $0
  puts CorrectHorseBatteryStaple.generate((ARGV[0] || 4).to_i)
end
