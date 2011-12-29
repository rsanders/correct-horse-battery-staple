# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = "correct-horse-battery-staple"
  s.version = "0.2.0.20111229043134"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Robert Sanders"]
  s.cert_chain = ["/Users/robertsanders/.gem/gem-public_cert.pem"]
  s.date = "2011-12-29"
  s.description = "Generate a 4 word password from words of size 3-8 characters, with\nfrequencies in the 30th-60th percentile. This range gives a nice set\nof uncommon but not completely alien words.\n\n    $ chbs generate --verbose -W 3..8 -P 30..60\n    Corpus size: 6396 candidate words of 33075 total\n    Entropy: 48 bits (2^48 = 281474976710656)\n    Years to guess at 1000 guesses/sec: 8926\n    magnate-thermal-sandbank-augur\n\nWith the --verbose flag, the utility will calculate a time-to-guess\nbased on a completely arbitrary 1000 guesses/sec.  If you'd like a\nmore secure password, either relax the various filtering rules (-W and\n-P), add more words to the password, or use a larger corpus.\n\nBy default we use the American TV Shows & Scripts corpus taken from\nWiktionary.\n\nOthers provided:\n\n* Project Gutenberg 2005 corpus taken from Wiktionary.\n* 1 of every 7 of the top 60000 lemmas from wordfrequency.info (6900\n  actual lemmas after processing)\n\nSee http://xkcd.com/936/ for the genesis of the idea.\n\nData sources:\n\n     http://en.wiktionary.org/wiki/Wiktionary:Frequency_lists\n     http://wordfrequency.info/"
  s.email = ["robert@curioussquid.com"]
  s.executables = ["chbs", "chbs-mkpass"]
  s.extra_rdoc_files = ["History.txt", "Manifest.txt", "README.txt"]
  s.files = ["Gemfile", "Gemfile.lock", "History.txt", "Manifest.txt", "README.txt", "Rakefile", "bin/chbs", "bin/chbs-mkpass", "corpus/gutenberg2005.csv", "corpus/gutenberg2005.json", "corpus/gutenberg2005.isam", "corpus/size100.csv", "corpus/size100.json", "corpus/tvscripts.csv", "corpus/tvscripts.json", "corpus/tvscripts.isam", "corpus/wordfrequency.csv", "corpus/wordfrequency.json", "corpus/wordfrequency.isam", "lib/correct_horse_battery_staple.rb", "lib/correct_horse_battery_staple/assembler.rb", "lib/correct_horse_battery_staple/corpus.rb", "lib/correct_horse_battery_staple/corpus/base.rb", "lib/correct_horse_battery_staple/corpus/serialized.rb", "lib/correct_horse_battery_staple/corpus/isam.rb", "lib/correct_horse_battery_staple/generator.rb", "lib/correct_horse_battery_staple/parser.rb", "lib/correct_horse_battery_staple/parser/base.rb", "lib/correct_horse_battery_staple/parser/regex.rb", "lib/correct_horse_battery_staple/range_parser.rb", "lib/correct_horse_battery_staple/statistical_array.rb", "lib/correct_horse_battery_staple/word.rb", "spec/corpus_spec.rb", "spec/correct_horse_battery_staple_spec.rb", "spec/fixtures/100.json", "spec/fixtures/corpus1.csv", "spec/fixtures/corpus100.json", "spec/fixtures/wiktionary1000.htm", "spec/range_parser_spec.rb", "spec/spec_helper.rb", "spec/statistical_array_spec.rb", "spec/support/spec_pry.rb", "spec/word_spec.rb", ".gemtest"]
  s.homepage = "http://github.com/rsanders/correct-horse-battery-staple"
  s.rdoc_options = ["--main", "README.txt"]
  s.require_paths = ["lib"]
  s.rubyforge_project = "correct-horse-battery-staple"
  s.rubygems_version = "1.8.10"
  s.signing_key = "/Users/robertsanders/.gem/gem-private_key.pem"
  s.summary = "Generate a 4 word password from words of size 3-8 characters, with frequencies in the 30th-60th percentile"

  if s.respond_to? :specification_version then
    s.specification_version = 3

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<commander>, [">= 4.0"])
      s.add_runtime_dependency(%q<fastercsv>, [">= 1.5.3"])
      s.add_runtime_dependency(%q<json>, [">= 1.6.0"])
      s.add_development_dependency(%q<rubyforge>, [">= 2.0.4"])
      s.add_development_dependency(%q<hoe>, ["~> 2.12"])
    else
      s.add_dependency(%q<commander>, [">= 4.0"])
      s.add_dependency(%q<fastercsv>, [">= 1.5.3"])
      s.add_dependency(%q<json>, [">= 1.6.0"])
      s.add_dependency(%q<rubyforge>, [">= 2.0.4"])
      s.add_dependency(%q<hoe>, ["~> 2.12"])
    end
  else
    s.add_dependency(%q<commander>, [">= 4.0"])
    s.add_dependency(%q<fastercsv>, [">= 1.5.3"])
    s.add_dependency(%q<json>, [">= 1.6.0"])
    s.add_dependency(%q<rubyforge>, [">= 2.0.4"])
    s.add_dependency(%q<hoe>, ["~> 2.12"])
  end
end
