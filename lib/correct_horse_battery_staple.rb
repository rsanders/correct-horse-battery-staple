require 'logger'

module CorrectHorseBatteryStaple
  VERSION = '0.6.2'

  DEFAULT_CORPUS_NAME = "tvscripts"

  SUPPORTED_FORMATS = %w[isam isamkd sqlite json csv marshal]

  class << self
    attr_accessor :logger
    attr_accessor :corpus_directory
  end
  self.logger = Logger.new(STDERR)

  def self.default_corpus
    self.load_corpus DEFAULT_CORPUS_NAME
  end

  def self.corpus_search_directories
    [self.corpus_directory]
  end

  def self.corpus_list(options = {})
    self.corpus_search_directories.map do |dir|
      Dir[File.join(dir, "*.{#{SUPPORTED_FORMATS.join(',')}}")].
        map {|file| options[:with_paths] ? File.expand_path(file) : File.basename(file, File.extname(file)) }
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
    if corpus_name.include?(':')
      return CorrectHorseBatteryStaple::Corpus.read corpus_name
    end

    formats = Array(formats || SUPPORTED_FORMATS)
    filename = corpus_name.match(/[.?]/) ? corpus_name :
      self.find_corpus(corpus_name, formats)
    unless (filename && File.exist?(filename))
      raise ArgumentError, "Cannot find corpus #{corpus_name}"
    end

    CorrectHorseBatteryStaple::Corpus.read filename
  end

  def self.generate(length = 4)
    CorrectHorseBatteryStaple::Generator.new(self.default_corpus).make(length)
  end

  protected


  module Common
    def logger
      CorrectHorseBatteryStaple.logger
    end

    if Object.const_defined?("Random")
      def random_number(max=1.0)
        Random.rand(max)
      end
    else
      def random_number(max=1.0)
        SecureRandom.random_number(max)
      end
    end

    def random_in_range(range)
      range.first + random_number(range_count(range))
    end

    def array_sample(array, count)
      l = array.length
      array.values_at(* count.times.map { random_number(l) })
    end

    def set_sample(array, count)
      l = array.length
      array.values_at(* count.times.map { random_number(l) })
    end
  end

  module Util
    def self.open_binary(filename, mode = "r", *rest)
      open(filename, openmode(mode), *rest)
    end

    def self.openmode(mode)
      IO.respond_to?(:binwrite) ? "#{mode}b:ASCII-8BIT" : mode
    end
  end

  autoload :Word,               'correct_horse_battery_staple/word'
  autoload :Stats,              'correct_horse_battery_staple/stats'
  autoload :Generator,          'correct_horse_battery_staple/generator'
  autoload :Corpus,             'correct_horse_battery_staple/corpus'
  autoload :Parser,             'correct_horse_battery_staple/parser'
  autoload :StatisticalArray,   'correct_horse_battery_staple/statistical_array'
  autoload :RangeParser,        'correct_horse_battery_staple/range_parser'
  autoload :Writer,             'correct_horse_battery_staple/writer'
  autoload :Backend,            'correct_horse_battery_staple/backend'
  autoload :Memoize,            'correct_horse_battery_staple/memoize'

  self.corpus_directory = File.join(File.dirname(__FILE__), "../corpus")
end

