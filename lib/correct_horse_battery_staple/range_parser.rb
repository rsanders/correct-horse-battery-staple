# doesn't handle X...Y

class CorrectHorseBatteryStaple::RangeParser
  NUM = '-?(?:\.[0-9]+|[0-9]+|[0-9]+\.[0-9]+|[0-9]+\.(?!\.))'
  SPACE = " *"
  SEPARATOR = "(-|\\.\\.)"
  REGEX_PAIR = Regexp.new("(#{NUM})#{SPACE}#{SEPARATOR}#{SPACE}(#{NUM})")
  REGEX_SINGLE = Regexp.new("#{SPACE}(#{NUM})#{SPACE}")
  def parse(string)
    match = string.match(REGEX_PAIR)
    if match
      return Range.new(parse_number(match[1]), parse_number(match[3]))
    end

    match = string.match(REGEX_SINGLE)
    if match
      num = parse_number(match[0])
      return Range.new(num, num)
    end

    nil
  end

  protected

  def parse_number(str)
    str.include?(".") ? str.to_f : str.to_i
  end
end
