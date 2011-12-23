#!/usr/bin/env ruby

require 'rubygems'
require 'open-uri'
require 'bigdecimal'
require 'fastercsv'

urls = %w[
  data/1-10000
  data/10001-20000
  data/20001-30000
  data/30001-40000
  data/40001-50000
  data/50001-60000
]

  # http://en.wiktionary.org/wiki/Wiktionary:Frequency_lists/PG/2005/08/1-10000
  # http://en.wiktionary.org/wiki/Wiktionary:Frequency_lists/PG/2005/08/10001-20000
  # http://en.wiktionary.org/wiki/Wiktionary:Frequency_lists/PG/2005/08/20001-30000
  # http://en.wiktionary.org/wiki/Wiktionary:Frequency_lists/PG/2005/08/30001-40000
  # http://en.wiktionary.org/wiki/Wiktionary:Frequency_lists/PG/2005/08/40001-50000
  # http://en.wiktionary.org/wiki/Wiktionary:Frequency_lists/PG/2005/08/50001-60000
  # http://en.wiktionary.org/wiki/Wiktionary:Frequency_lists/PG/2005/08/60001-70000

def mean(array)
  array.inject(0) { |sum, x| sum += x } / array.size.to_f
end
def mean_and_standard_deviation(array)
  m = mean(array)
  variance = array.inject(0) { |variance, x| variance += (x - m) ** 2 }
  return m, Math.sqrt(variance/(array.size-1))
end

class WStruct < Struct.new(:word, :frequency, :rank, :dispersion)
  include Comparable
  def <=>(other)
    self.frequency <=> other.frequency
  end
end

parsers = {
  :wikitionary   =>  [%r{<a href="/wiki/\w+" title="(\w+)">\w+</a> = (\d+)},
    lambda {|match, wstruct| wstruct.word = match[0]; wstruct.frequency = match[1].to_i }],
  :wikitionary_debug   =>  [%r{<a href="/wiki/\w+" title="(\w+)">\w+</a> = (\d+)},
    lambda {|match, wstruct| puts "match: #{match.inspect}";
      wstruct.word = match[0]; wstruct.frequency = match[1].to_i
      puts "wstruct is #{wstruct.inspect}"
    }],

  # rank	lemma	PoS	freq	dispersion
  # 7	to	t	6332195	0.98
  :wordfrequency => [ %r{^(\d+)\t(\w+)\t\w\t(\d+)\t([0-9.])$},
    lambda {|match, wstruct| wstruct.word = match[1]; wstruct.frequency = match[3] }]
}

(regex, lexer) = parsers[:wikitionary]

words = urls.map do |url|
  open(url).read.scan(regex).map do |pair|
    WStruct.new.tap {|w| lexer.call(pair, w) }
  end
end.reduce(:+)

# total number of words
count       = words.length

# assign ranks
words.each_with_index {|word, i| word.rank = count-i }

frequencies = words.map {|pair| pair.frequency }
total       = frequencies.reduce(BigDecimal.new("0"), :+)


(prob_mean, prob_stddev) = mean_and_standard_deviation(frequencies.map {|freq| (freq/total) * 100})
(mean, stddev)           = mean_and_standard_deviation(frequencies)

puts "index,rank,word,frequency,percentile,distance,probability,distance_probability"
words[1..20].each_with_index do |wstruct, index|
  word = wstruct.word
  freq = wstruct.frequency
  distance        = (freq-mean)/stddev
  probability     = freq/total
  distance_prob   = (probability - prob_mean) / prob_stddev
  percentile      = (index-0.5)/count * 100
  printf("%d,%d,%s,%d,%.2f,%.6f,%.8f,%.8f\n", index, wstruct.rank, word, freq,
    percentile, distance, probability * 100, distance_prob)
end

# -*- mode: Ruby; compile-command; ./mkcorpus.rb -*-
