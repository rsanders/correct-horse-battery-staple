class CorrectHorseBatteryStaple::Writer::Isamkd < CorrectHorseBatteryStaple::Writer::File
  include CorrectHorseBatteryStaple::Backend::IsamKD
  
  def initialize(dest, options={})
    super
  end

  def write_corpus(corpus)
    write_corpus_to_io(corpus, io)
  end

end
