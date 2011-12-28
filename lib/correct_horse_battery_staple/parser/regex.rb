
class CorrectHorseBatteryStaple::Parser
  class Regex < Base
    PARSERS  = {
        :wiktionary   =>  [%r{<a href="/wiki/\w+" title="(\w+)">\w+</a> = (\d+)},
          lambda {|match| CorrectHorseBatteryStaple::Word.new(:word => match[0], :frequency => match[1].to_i) }],

        # rank	lemma	PoS	freq	dispersion
        # 7	to	t	6332195	0.98
        :wordfrequency => [ %r{^(\d+)\s+(\w+)\s+\w*\s+(\d+)\s+([0-9.]+)$},
        lambda {|match| CorrectHorseBatteryStaple::Word.new(:word => match[1],
            :rank => match[0].to_f,
            :frequency => match[3].to_f,
            :dispersion => match[4].to_f)
        }]
    }

    def initialize(type = :wiktionary)
      @parser_type = type.to_sym
    end

    def parse(file)
      raise ArgumentError, "unknown regex parser type #{@parser_type}" unless PARSERS.has_key?(@parser_type)
      (regex, lexer) = PARSERS[@parser_type]

      words = 
        file.read.scan(regex).map do |match|
          lexer.call(match)
        end

    end
  end
end
