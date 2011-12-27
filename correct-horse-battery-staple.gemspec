# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = "correct-horse-battery-staple"
  s.version = "0.1.0.20111227093726"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Robert Sanders"]
  s.date = "2011-12-27"
  s.description = "FIX (describe your package)"
  s.email = ["robert@curioussquid.com"]
  s.executables = ["crbs", "crbs-mkcorpus", "crbs-mkpass"]
  s.extra_rdoc_files = ["History.txt", "Manifest.txt", "README.txt"]
  s.files = ["Gemfile", "Gemfile.lock", "History.txt", "Manifest.txt", "README.txt", "Rakefile", "bin/crbs", "bin/crbs-mkcorpus", "bin/crbs-mkpass", "corpus/wiktionary.csv", "lib/correct_horse_battery_staple.rb", "lib/correct_horse_battery_staple/corpus.rb", "lib/correct_horse_battery_staple/generator.rb", "lib/correct_horse_battery_staple/parser.rb", "lib/correct_horse_battery_staple/parser/base.rb", "lib/correct_horse_battery_staple/parser/regex.rb", "lib/correct_horse_battery_staple/statistical_array.rb", "spec/corpus_spec.rb", "spec/correct_horse_battery_staple_spec.rb", "spec/fixtures/corpus1.csv", "spec/spec_helper.rb", "spec/statistical_array_spec.rb", ".gemtest"]
  s.homepage = "FIX (url)"
  s.rdoc_options = ["--main", "README.txt"]
  s.require_paths = ["lib"]
  s.rubyforge_project = "correct-horse-battery-staple"
  s.rubygems_version = "1.8.10"
  s.summary = "FIX (describe your package)"

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
