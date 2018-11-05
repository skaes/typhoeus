require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe Typhoeus::RemoteMethod do
  it "should take options" do
    Typhoeus::RemoteMethod.new(:body => "foo")
  end
  
  describe "http_method" do
    it "should return the http method" do
      m = Typhoeus::RemoteMethod.new(:method => :put)
      expect(m.http_method).to eq(:put)
    end
    
    it "should default to :get" do
      m = Typhoeus::RemoteMethod.new
      expect(m.http_method).to eq(:get)
    end
  end
  
  it "should return the options" do
    m = Typhoeus::RemoteMethod.new(:body => "foo")
    expect(m.options).to eq({:body => "foo"})
  end
  
  it "should pull uri out of the options hash" do
    m = Typhoeus::RemoteMethod.new(:base_uri => "http://pauldix.net")
    expect(m.base_uri).to eq("http://pauldix.net")
    expect(m.options).not_to have_key(:base_uri)
  end
  
  describe "on_success" do
    it "should return the block" do
      m = Typhoeus::RemoteMethod.new(:on_success => lambda {:foo})
      expect(m.on_success.call).to eq(:foo)
    end
  end
  
  describe "on_failure" do
    it "should return method name" do
      m = Typhoeus::RemoteMethod.new(:on_failure => lambda {:bar})
      expect(m.on_failure.call).to eq(:bar)
    end
  end
  
  describe "path" do
    it "should pull path out of the options hash" do
      m = Typhoeus::RemoteMethod.new(:path => "foo")
      expect(m.path).to eq("foo")
      expect(m.options).not_to have_key(:path)
    end
    
    it "should output argument names from the symbols in the path" do
      m = Typhoeus::RemoteMethod.new(:path => "/posts/:post_id/comments/:comment_id")
      expect(m.argument_names).to eq([:post_id, :comment_id])
    end
    
    it "should output an empty string when there are no arguments in path" do
      m = Typhoeus::RemoteMethod.new(:path => "/default.html")
      expect(m.argument_names).to eq([])
    end
    
    it "should output and empty string when there is no path specified" do
      m = Typhoeus::RemoteMethod.new
      expect(m.argument_names).to eq([])
    end
    
    it "should interpolate a path with arguments" do
      m = Typhoeus::RemoteMethod.new(:path => "/posts/:post_id/comments/:comment_id")
      expect(m.interpolate_path_with_arguments(:post_id => 1, :comment_id => "asdf")).to eq("/posts/1/comments/asdf")
    end
    
    it "should provide the path when interpolated called and there is nothing to interpolate" do
      m = Typhoeus::RemoteMethod.new(:path => "/posts/123")
      expect(m.interpolate_path_with_arguments(:foo => :bar)).to eq("/posts/123")
    end
  end
  
  describe "#merge_options" do
    it "should keep the passed in options first" do
      m = Typhoeus::RemoteMethod.new("User-Agent" => "whatev", :foo => :bar)
      expect(m.merge_options({"User-Agent" => "http-machine"})).to eq({"User-Agent" => "http-machine", :foo => :bar})
    end
    
    it "should combine the params" do
      m = Typhoeus::RemoteMethod.new(:foo => :bar, :params => {:id => :asdf})
      expect(m.merge_options({:params => {:desc => :jkl}})).to eq({:foo => :bar, :params => {:id => :asdf, :desc => :jkl}})
    end
  end
  
  describe "memoize_reponses" do
    before(:each) do
      @m = Typhoeus::RemoteMethod.new(:memoize_responses => true)
      @args    = ["foo", "bar"]
      @options = {:asdf => {:jkl => :bar}}
    end
    
    it "should store if responses should be memoized" do
      expect(@m.memoize_responses?).to eq(true)
      expect(@m.options).to eq({})
    end
    
    it "should tell when a method is already called" do
      expect(@m.already_called?(@args, @options)).to eq(false)
      @m.calling(@args, @options)
      expect(@m.already_called?(@args, @options)).to eq(true)
      expect(@m.already_called?([], {})).to eq(false)
    end
    
    it "should call response blocks and clear the methods that have been called" do
      response_block_called = double('response_block')
      expect(response_block_called).to receive(:call).exactly(1).times
      
      @m.add_response_block(lambda {|res| expect(res).to eq(:foo); response_block_called.call}, @args, @options)
      @m.calling(@args, @options)
      @m.call_response_blocks(:foo, @args, @options)
      expect(@m.already_called?(@args, @options)).to eq(false)
      @m.call_response_blocks(:asdf, @args, @options) #just to make sure it doesn't actually call that block again
    end
  end
  
  describe "cache_reponses" do
    before(:each) do
      @m = Typhoeus::RemoteMethod.new(:cache_responses => true)
      @args    = ["foo", "bar"]
      @options = {:asdf => {:jkl => :bar}}
    end
    
    it "should store if responses should be cached" do
      expect(@m.cache_responses?).to eq(true)
      expect(@m.options).to eq({})
    end
    
    it "should force memoization if caching is enabled" do
      expect(@m.memoize_responses?).to eq(true)
    end
    
    it "should store cache ttl" do
      expect(Typhoeus::RemoteMethod.new(:cache_responses => 30).cache_ttl).to eq(30)
    end
  end
end
