
GEM_DIR = File.expand_path(File.join(File.dirname(__FILE__), ".."))
LIB_DIR = File.join(GEM_DIR, "lib")
BIN_DIR = File.join(GEM_DIR, "bin")

SPEC_DIR = File.join(GEM_DIR, "spec")
FIXTURES_DIR = File.join(SPEC_DIR, "fixtures")

$:.unshift LIB_DIR

require 'bundler'
Bundler.setup

require 'pry'
require 'rspec'

Dir[File.join(File.dirname(__FILE__),'support','**','*.rb')].each { |f| require File.expand_path(f) }


require 'correct_horse_battery_staple'
