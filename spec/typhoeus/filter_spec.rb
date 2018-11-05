require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe Typhoeus::Filter do
  it "should take a method name and optionally take options" do
    filter = Typhoeus::Filter.new(:bar, :only => :foo)
    filter = Typhoeus::Filter.new(:bar)
  end
  
  describe "#apply_filter?" do
    it "should return true for any method when :only and :except aren't specified" do
      filter = Typhoeus::Filter.new(:bar)
      expect(filter.apply_filter?(:asdf)).to eq(true)
    end
    
    it "should return true if a method is in only" do
      filter = Typhoeus::Filter.new(:bar, :only => :foo)
      expect(filter.apply_filter?(:foo)).to eq(true)
    end
    
    it "should return false if a method isn't in only" do
      filter = Typhoeus::Filter.new(:bar, :only => :foo)
      expect(filter.apply_filter?(:bar)).to eq(false)
    end
    
    it "should return true if a method isn't in except" do
      filter = Typhoeus::Filter.new(:bar, :except => :foo)
      expect(filter.apply_filter?(:bar)).to eq(true)
    end
    
    it "should return false if a method is in except" do
      filter = Typhoeus::Filter.new(:bar, :except => :foo)
      expect(filter.apply_filter?(:foo)).to eq(false)
    end
  end
end
