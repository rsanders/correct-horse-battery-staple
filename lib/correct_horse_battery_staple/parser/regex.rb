
class CorrectHorseBatteryStaple::Parser
  class Regex < Base
    PARSERS  = {
        :wikitionary   =>  [%r{<a href="/wiki/\w+" title="(\w+)">\w+</a> = (\d+)},
          lambda {|match, wstruct| wstruct.word = match[0]; wstruct.frequency = match[1].to_i }],

        # rank	lemma	PoS	freq	dispersion
        # 7	to	t	6332195	0.98
        :wordfrequency => [ %r{^(\d+)\t(\w+)\t\w\t(\d+)\t([0-9.])$},
          lambda {|match, wstruct| wstruct.word = match[1]; wstruct.frequency = match[3] }]
    }

    def initialize(type = :wiktionary)
      super
      @parser_type = type.to_sym
    end

    def parse(file)
      raise ArgumentError, "unknown regex parser type #{file}" unless PARSERS.has_key?[@parser_type]
      (regex, lexer) = PARSERS[@parser_type]

      words = urls.map do |url|
        file.read.scan(regex).map do |pair|
           WStruct.new.tap {|w| lexer.call(pair, w) }
        end
      end.reduce(:+)
    end
  end
end
