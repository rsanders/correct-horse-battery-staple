#
# Base class for all writers
#

class CorrectHorseBatteryStaple::Writer::Base < CorrectHorseBatteryStaple::Writer
  attr_accessor :dest, :options

  def initialize(dest, options = {})
    self.dest    = dest
    self.options = options
  end

  def write_corpus(corpus)
    raise NotImplementedError, "#{self.class.name} is not a complete implementation"
  end

  def close
  end
end
