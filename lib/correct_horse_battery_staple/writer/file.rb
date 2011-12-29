#
# base class for file-based stores
#
#
class CorrectHorseBatteryStaple::Writer::File < CorrectHorseBatteryStaple::Writer::Base
  attr_accessor :io

  def initialize(dest, options = {})
    super

    @do_close = false
    if dest.respond_to?(:write)
      self.io = dest
    else
      if ["/dev/stdout", "-"].include?(dest)
        self.io = STDOUT
      else
        self.io = open(dest, openmode)
        @do_close = true
      end
    end
  end

  def close
    return unless @do_close
    self.io.close rescue nil
  ensure
    self.io = nil
    @do_close = false
  end

  protected

  def openmode
    "w"
  end

  def <<(string)
    self.io.write string
  end

  def print(string)
    self.io.print string
  end

  def puts(string)
    self.io.puts string
  end

  def write(string)
    self.io.write string
  end

end
