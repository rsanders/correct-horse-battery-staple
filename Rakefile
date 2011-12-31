# -*- ruby -*-

require 'rubygems'
require 'hoe'

# Hoe.plugin :compiler
# Hoe.plugin :gem_prelude_sucks
# Hoe.plugin :inline
# Hoe.plugin :racc

Hoe.plugin :bundler
Hoe.plugin :git
Hoe.plugin :rubyforge
Hoe.plugin :gemspec

Hoe.spec 'correct-horse-battery-staple' do
  developer('Robert Sanders', 'robert@curioussquid.com')
  dependency 'commander', '>= 4.0'
  dependency 'fastercsv', '>= 1.5.3'
  dependency 'json', '>= 1.6.0'
end

namespace :chbs do
  task :generate_corpus => "corpus/tvscripts.json"

  file "corpus/tvscripts.json" do |task|
    sh "./script/generate_all"
  end
  task :corpus => "corpus/tvscripts.json"

  task :clean do
    sh "rm -f corpus/*"
  end
end

task :corpus => "chbs:corpus"

["gem", "spec", "install_gem"].each do |task|
  Rake::Task[task].prerequisites.unshift "chbs:corpus"
end
task :clean => "chbs:clean"

# -*- mode: Ruby -*-
