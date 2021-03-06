#
# Base class for all writers
#

class CorrectHorseBatteryStaple::Writer::Base < CorrectHorseBatteryStaple::Writer
  include CorrectHorseBatteryStaple::Common

  attr_accessor :dest, :options

  def initialize(dest, options = {})
    self.dest    = dest
    self.options = options
    initialize_backend_variables if respond_to?(:initialize_backend_variables)
  end

  def write_corpus(corpus)
    raise NotImplementedError, "#{self.class.name} is not a complete implementation"
  end

  def close
  end
end
