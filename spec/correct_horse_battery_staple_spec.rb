require File.join(File.dirname(__FILE__), "spec_helper")

describe CorrectHorseBatteryStaple do

  subject { CorrectHorseBatteryStaple }

  context 'static methods' do

    it { should respond_to(:default_corpus)   }
    it { should respond_to(:generate) }

    context '.default_corpus' do
      let :defcorp do
        CorrectHorseBatteryStaple.default_corpus
      end

      before do
        CorrectHorseBatteryStaple.should_receive(:corpus_directory).and_return(FIXTURES_DIR)
        CorrectHorseBatteryStaple::Corpus.should_receive(:read_csv).and_return(27)
      end

      it "should make the right subcalls" do
        defcorp
      end

      it "should return the right answer" do
        defcorp.should == 27
      end
    end
  end

end


