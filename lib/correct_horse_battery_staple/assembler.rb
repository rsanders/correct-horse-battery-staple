class Correct_Horse_Battery_Staple::Assembler

  attr_accessor :freq_mean, :freq_stddev
  attr_accessor :prob_mean, :prob_stddev
  attr_accessor :corpus_size
  attr_accessor :weighted_corpus_size

  def read(sources)

    parser_class = CorrectHorseBatteryStaple::Parser::Regex

    urls = ARGV

    urls.map do |url|
      parser_class.new.parse open(url)
    end.reduce(:+).select {|wstruct| wstruct.word =~ /^[a-zA-Z]/ }
  end

  def frequencies
    @frequencies ||= CorrectHorseBatteryStaple::StatisticalArray.new(words.map {|pair| pair.frequency })
  end

  def process(words)
    self.corpus_size           = words.length

    # assign ranks
    words.each_with_index {|word, i| word.rank = corpus_size-i }

    frequencies                = frequencies
    self.weighted_corpus_size  = frequencies.reduce(BigDecimal.new("0"), :+)

    (self.prob_mean, self.prob_stddev)    = CorrectHorseBatteryStaple::StatisticalArray.new(frequencies.map do |freq|
        (freq/weighted_corpus_size) * 100
      end).mean_and_standard_deviation
    (self.freq_mean, self.freq_stddev)    = frequencies.mean_and_standard_deviation
  end

  def save_as_csv(io)
    io.puts "index,rank,word,frequency,percentile,distance,probability,distance_probability"
    words.each_with_index do |wstruct, index|
      word            = wstruct.word
      freq            = wstruct.frequency
      distance        = (freq-freq_mean)/freq_stddev
      probability     = freq/weighted_corpus_size
      distance_prob   = (probability - prob_mean) / prob_stddev
      percentile      = (index-0.5)/corpus_size * 100
      io.puts sprintf("%d,%d,\"%s\",%d,%.4f,%.6f,%.8f,%.8f\n", index, wstruct.rank, word, freq,
        percentile, distance, probability * 100, distance_prob)
    end
  end

end
