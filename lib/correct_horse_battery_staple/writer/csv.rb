class CorrectHorseBatteryStaple::Writer::Csv < CorrectHorseBatteryStaple::Writer::File

  def initialize(dest, options={})
    super
  end

  def write_corpus(corpus)
    puts "index,rank,word,frequency,percentile,distance,probability,distance_probability"
    corpus.each_with_index do |w, index|
      puts sprintf("%d,%d,\"%s\",%d,%.4f,%.6f,%.8f,%.8f\n",
        index || -1, w.rank || -1, w.word, w.frequency || -1,
        w.percentile || -1, w.distance || -1, w.probability || -1, w.distance_probability || -1)
    end
  end
end
