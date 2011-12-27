require File.join(File.dirname(__FILE__), "spec_helper")

describe CorrectHorseBatteryStaple::Corpus do

  subject { corpus }

  let :json_file do
    File.join(FIXTURES_DIR, "100.json")
  end

  let :corpus do
    CorrectHorseBatteryStaple::Corpus.read_json json_file
  end

  context 'loading CSV' do
    subject { corpus }

    it "should be the right size" do
      subject.length.should == 100
    end

    it "should have a word column" do
      subject[0][:word].should_not be_empty
    end
  end

  context 'filtering' do
    it { should respond_to(:filter) }
    it { should respond_to(:result) }

    let :evens do
      corpus.filter {|entry| entry[:word].length % 2 == 0}
    end

    let :no_ys do
      evens.filter {|entry| ! entry[:word].include?('y') }
    end

    it 'should return the same corpus from a call to #filter' do
      evens.should equal(corpus)
    end

    it 'should allow multiple calls to #filter' do
      no_ys.should == evens
    end

    it 'should implement #result' do
      evens.should respond_to(:result)
    end

    it 'should return a new object from #result'  do
      evens.result.should_not equal(corpus)
      evens.result.should be_instance_of(CorrectHorseBatteryStaple::Corpus)
    end

    it 'should reduce the count with one filter'  do
      evens.result.length.should_not == corpus.length
    end
  end
end

# -*- mode: Ruby; compile-command: "rspec corpus_spec.rb" -*-
