class CorrectHorseBatteryStaple::Writer::Marshal < CorrectHorseBatteryStaple::Writer::File

  def initialize(dest, options={})
    super
  end

  def write_corpus(corpus)
    write ::Marshal.dump(corpus)
  end
end
