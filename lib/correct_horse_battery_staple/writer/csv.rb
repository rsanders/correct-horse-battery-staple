class CorrectHorseBatteryStaple::Writer::Csv < CorrectHorseBatteryStaple::Writer::File

  def initialize(dest, options={})
    super
  end

  def write_corpus(corpus)
    puts "index,rank,word,frequency,percentile,distance,probability,distance_probability"
    corpus.each_with_index do |w, index|
      puts sprintf("%d,%d,\"%s\",%d,%.4f,%.6f,%.8f,%.8f\n",
        index, w.rank, w.word, w.frequency || 0,
        w.percentile || 0, w.distance || 0, w.probability || 0, w.distance_probability || 0)
    end
  end
end
