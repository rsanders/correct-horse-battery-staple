class CorrectHorseBatteryStaple::Writer::Json < CorrectHorseBatteryStaple::Writer::File

  def initialize(dest, options={})
    super
  end

  def write_corpus(corpus)
    print '{"stats": '
    print corpus.stats.to_json
    print ', "corpus": ['
    i = 0
    corpus.each do |word|
      puts "," if i >= 1
      print(word.to_hash.to_json)
      i += 1
    end
    puts "]\n}"
  end
end
