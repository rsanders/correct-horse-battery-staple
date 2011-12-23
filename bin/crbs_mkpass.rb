#!/usr/bin/env ruby

require 'correct_horse_battery_staple'

puts CorrectHorseBatteryStaple.new(3..6).
  make((ARGV[0] || 4).to_i)
