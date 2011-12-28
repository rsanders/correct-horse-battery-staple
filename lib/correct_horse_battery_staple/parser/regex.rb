
class CorrectHorseBatteryStaple::Parser
  class Regex < Base
    PARSERS  = {
        :wiktionary   =>  [%r{<a href="/wiki/\w+" title="(\w+)">\w+</a> = (\d+)},
          lambda {|match| CorrectHorseBatteryStaple::Word.new(:word => match[0], :frequency => match[1].to_i) }],

        # rank	lemma	PoS	freq	dispersion
        # 7	to	t	6332195	0.98
        :wordfrequency => [ %r{^(\d+)\s+(\w+)\s+\w*\s+(\d+)\s+([0-9.]+)},
        lambda {|match| CorrectHorseBatteryStaple::Word.new(:word => match[1],
            :rank => match[0].to_f,
            :frequency => match[3].to_f,
            :dispersion => match[4].to_f)
        }],

        # using tabs between columns
        # freq    word    PoS     # texts
        # -----   -----   -----   -----
        # 22995878        the     at      169011
        # 11239776        and     cc      168844
        :coca => [ %r{^(\d+)\s+(\w+)\s+\w*\s+(\d+)},
        lambda {|match| CorrectHorseBatteryStaple::Word.new(:word => match[1],
            :frequency => match[0].to_i,
            :texts => match[2].to_i)
        }],

      # <tr>
      # <td>25</td>
      # <td><a href="/wiki/be" title="be">be</a></td>
      # <td>191823</td>
      # </tr>
      :tvscripts => [
        Regexp.new('<tr>.*?<td>(\d+)</td>.*?<td>.*?title="(\w+)".*?</td>.*?<td>(\d+)</td>.*?</tr>', Regexp::MULTILINE),
        lambda {|match| CorrectHorseBatteryStaple::Word.new(
            :rank => match[0].to_i,
            :word => match[1],
            :frequency => match[2].to_i
            ) }
      ]
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
