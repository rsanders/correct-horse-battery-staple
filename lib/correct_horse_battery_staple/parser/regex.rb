
class CorrectHorseBatteryStaple::Parser
  class Regex < Base
    PARSERS  = {
        :wiktionary   =>  [%r{<a href="/wiki/\w+" title="(\w+)">\w+</a> = (\d+)},
          lambda {|match, wstruct| wstruct.word = match[0]; wstruct.frequency = match[1].to_i }],

        # rank	lemma	PoS	freq	dispersion
        # 7	to	t	6332195	0.98
        :wordfrequency => [ %r{^(\d+)\t(\w+)\t\w\t(\d+)\t([0-9.])$},
          lambda {|match, wstruct| wstruct.word = match[1]; wstruct.frequency = match[3] }]
    }

    def initialize(type = :wiktionary)
      @parser_type = type.to_sym
    end

    def parse(file)
      raise ArgumentError, "unknown regex parser type #{@parser_type}" unless PARSERS.has_key?(@parser_type)
      (regex, lexer) = PARSERS[@parser_type]

      words = 
        file.read.scan(regex).map do |pair|
           WStruct.new.tap {|w| lexer.call(pair, w) }
        end

    end
  end
end
