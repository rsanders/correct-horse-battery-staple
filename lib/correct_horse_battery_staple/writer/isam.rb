class CorrectHorseBatteryStaple::Writer::Isam < CorrectHorseBatteryStaple::Writer::File

  def initialize(dest, options={})
    super
  end

  def fix_stats(stats)
    stats.each do |k,v|
      if v.respond_to?(:nan?) && v.nan?
        stats[k] = -1
      end
    end
    stats
  end

  def write_corpus(corpus)
    # includes prefix length byte
    @word_length = corpus.reduce(0) { |m, e| m > e.word.length ? m : e.word.length } + 1
    @freq_length = 4
    @entry_length = @word_length + @freq_length

    stats = fix_stats(corpus.stats)

    prelude = {
      "wlen"     => @word_length,
      "flen"     => 4,
      "entrylen" => @word_length + @freq_length,
      "sort"     => "frequency",
      "n"        => corpus.length,
      "stats"    => stats
    }.to_json
    record_offset = [((prelude.length+8.0)/512).ceil, 1].max * 512
    io.write(pre=[record_offset, prelude.length, prelude].pack("NNA#{record_offset-8}"))
    # STDERR.puts "pre size is #{pre.length}"
    corpus.each_with_index do |w, index|
      io.write(s=[w.word.length, w.word, w.frequency].pack("Ca#{@word_length-1}N"))
      # STDERR.puts "s size is #{s.length}"
    end
  end

  def binwrite(*args)
    method = io.respond_to?(:binwrite) ? :binwrite : :write
    io.send(method, *args)
  end

  def openmode
    IO.respond_to?(:binwrite) ? "wb:ASCII-8BIT" : "w"
  end

end
