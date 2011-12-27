require File.join(File.dirname(__FILE__), "spec_helper")

require 'json'

describe CorrectHorseBatteryStaple::Word do

  let :options do
    {:word => "someword", :frequency => 132134, :rank => 11}
  end

  let :word do
    CorrectHorseBatteryStaple::Word.new(options)
  end

  context "creation from hash" do
    it "should successfully create from options" do
      word.should be_instance_of(CorrectHorseBatteryStaple::Word)
    end

    it "should contain the correct word" do
      word.word.should == "someword"
    end

    it "should contain the correct frequency" do
      word.frequency.should == 132134
    end

    it "should contain the correct rank" do
      word.rank.should == 11
    end

    it "should fail when given an options hash without a word" do
      expect { CorrectHorseBatteryStaple::Word.new({}) }.
        to   raise_error
    end
  end

  context "access to member" do
    it "should allow access via .ATTR accessor" do
      word.word.should == "someword"
    end

    it "should allow access via [:ATTR] accessor" do
      word[:word].should == "someword"
    end

    it 'should allow access via ["ATTR"] accessor' do
      word["word"].should == "someword"
    end
  end

  context "setting member" do
    it "should allow setting via .ATTR accessor" do
      word.word = "newword"
      word.word.should == "newword"
    end

    it "should allow access via [:ATTR] accessor" do
      word[:word] = "newword"
      word.word.should == "newword"
    end

    it 'should allow access via ["ATTR"] accessor' do
      word["word"] = "newword"
      word.word.should == "newword"
    end
  end

  context "conversions" do
    context "to hash" do
      subject { word.to_hash }

      it "should contain the key elements" do
        subject.should have_key("word")
      end

      it "should not contain unset elements" do
        subject.should_not have_key("probability")
      end
    end

    context "to JSON" do
      subject { word.to_json }

      it "should be properly formatted JSON" do
        expect { JSON.parse(subject) }.
          not_to raise_error
        JSON.parse(subject) == word.to_hash
      end

    end
  end
end

# -*- mode: Ruby -*-
