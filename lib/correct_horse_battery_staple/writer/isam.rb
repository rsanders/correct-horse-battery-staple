class CorrectHorseBatteryStaple::Writer::Isam < CorrectHorseBatteryStaple::Writer::File

  def initialize(dest, options={})
    super
    # including prefix length byte
    @word_length = 26
    @freq_length = 4
    @entry_length = @word_length + @freq_length
  end

  def write_corpus(corpus)
    prelude = {"wlen" => @word_length, "flen" => 4, "entrylen" => @entry_length}.to_json
    record_offset = [((prelude.length+8.0)/512).ceil, 1].max * 512
    io.write (pre=[record_offset, prelude.length, prelude].pack("NNA#{record_offset-8}"))
    # STDERR.puts "pre size is #{pre.length}"
    corpus.each_with_index do |w, index|
      io.write (s=[w.word.length, w.word, w.frequency].pack("Ca#{@word_length-1}N"))
      # STDERR.puts "s size is #{s.length}"
    end
  end
end
