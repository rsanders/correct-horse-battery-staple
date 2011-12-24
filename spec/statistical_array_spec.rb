require File.join(File.dirname(__FILE__), "spec_helper")

describe CorrectHorseBatteryStaple::StatisticalArray do

  context 'construction' do

    let :base_array do
      [1,3,3,5,7,9,10,12,12,12,18,30,40,45,50,60]
    end
    subject { CorrectHorseBatteryStaple::StatisticalArray.new base_array }

    context 'basic functions' do
      it "should be the correct size" do
        subject.length.should == 16
      end

      it "should calculate mean" do
        sprintf("%.4f", subject.mean).should == "19.8125"
        # subject.mean.should =~ 5.42857142857143
      end

      it "should calculate stddev" do
        sprintf("%.4f", subject.standard_deviation).should == "18.9287"
      end
    end

    context 'percentiles to index' do
      it "should calculate an index by for a percentile" do
        subject.percentile_index(50).should == 9
      end
    end

    context 'elements for a percentile range' do
      it "when given a range" do
        subject.select_percentile(50..70).should == [12, 12, 18, 30, 40]
      end

      it "when given a single number" do
        subject.select_percentile(40).should == [10, 12]
      end

      it "at the low end" do
        subject.select_percentile(0..10).should == [1, 3, 3, 5]
      end
    end


  end

end


