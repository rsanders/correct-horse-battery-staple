require File.join(File.dirname(__FILE__), "spec_helper")

describe CorrectHorseBatteryStaple do

  subject { CorrectHorseBatteryStaple }

  let :small_corpus do
    CorrectHorseBatteryStaple.load_corpus(File.join(FIXTURES_DIR, "corpus100.json"))
  end
  
  context 'static methods' do

    it { should respond_to(:default_corpus)   }
    it { should respond_to(:generate) }
    it { should respond_to(:load_corpus)   }
    it { should respond_to(:find_corpus)   }

    context '.default_corpus' do
      let :defcorp do
        CorrectHorseBatteryStaple.default_corpus
      end

      before do
        CorrectHorseBatteryStaple.should_receive(:load_corpus).
          with(CorrectHorseBatteryStaple::DEFAULT_CORPUS_NAME).
          and_return(27)
      end

      it 'should call load_corpus' do
       defcorp.should == 27
      end
    end

    context '.generate' do
      subject { CorrectHorseBatteryStaple.generate(3) }

      before do
        CorrectHorseBatteryStaple.should_receive(:default_corpus).
          at_least(1).times.
          and_return(small_corpus)
      end

      it 'should return a string of 3 words separated by dashes' do
        subject.split(/-/).should have(3).items
      end

      it 'should not return the same string twice' do
        CorrectHorseBatteryStaple.generate(3).should_not ==
          CorrectHorseBatteryStaple.generate(3)
      end

      it 'should respond to different string sizes' do
        CorrectHorseBatteryStaple.generate(4).split(/-/).should have(4).items
      end
    end

    context '.load_corpus' do
      context 'given a file path' do
        it 'should load a file by path'
        it 'should detect the format from extension'
      end

      context 'in a standard search directory' do
        it 'should load a corpus by name'
        it 'should load a corpus by name w/extension'
        it 'should detect the format from extension'
      end
    end

  end

end

