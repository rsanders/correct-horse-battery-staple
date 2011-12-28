require File.join(File.dirname(__FILE__), "spec_helper")

describe CorrectHorseBatteryStaple::RangeParser do

  let :parser do
    CorrectHorseBatteryStaple::RangeParser.new
  end

  shared_examples_for "integer range" do
    subject { parser.parse(range_string) }

    it 'should return a range given valid endpoints' do
      subject.should be_instance_of(Range)
    end
    it 'should equal the expected range' do
      subject.should == expected_range
    end
    it 'should have integer endpoints' do
      subject.begin.should be_instance_of(Integer)
      subject.end.  should be_instance_of(Integer)
    end
  end

  dotted_ranges =
    [[0..1, "0..1"],
    [0..-1, "0..-1"],
    [-10..3, "-10..3"],
    [-10.0..2.0, "-10.0..2.0"]]

  dashed_ranges =
    dotted_ranges.map do |(range, string)|
      [range, string.gsub(/\.\./, '-')]
  end +
    [[100..200, "100-200"],
    [-5..-1, "-5--1"],
    [5..-1, "5--1"],
    [1.0..3, "1.-3"]]

  scalar_ranges =
    [[-10..-10, "-10"],
    [0..0, "0"],
    [0.5..0.5, ".5"],
    [-2..-2, "-2"],
    [-0.2..-0.2, "-.2"]]

  (dotted_ranges + dashed_ranges + scalar_ranges).each do |(range, string)|
    it "should parse '#{string}' into [#{range}]" do
      parser.parse(string).should == range
    end
  end

end

# -*- mode: Ruby -*-
