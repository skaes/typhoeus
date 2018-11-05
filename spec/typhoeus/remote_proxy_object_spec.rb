require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe Typhoeus::RemoteProxyObject do
  before(:each) do
    @easy = Typhoeus::Easy.new
    @easy.method = :get
    @easy.url    = "http://localhost:3001"
  end
  
  it "should take a caller and call the clear_memoized_proxy_objects" do
    clear_proxy = lambda {}
    expect(clear_proxy).to receive(:call)
    response = Typhoeus::RemoteProxyObject.new(clear_proxy, @easy)
    expect(response.code).to eq(200)
  end

  it "should take an easy object and return the body when requested" do
    response = Typhoeus::RemoteProxyObject.new(lambda {}, @easy)
    expect(@easy.response_code).to eq(0)
    expect(response.code).to eq(200)
  end
  
  it "should perform requests only on the first access" do
    response = Typhoeus::RemoteProxyObject.new(lambda {}, @easy)
    expect(response.code).to eq(200)
    expect(Typhoeus).to receive(:perform_easy_requests).exactly(0).times
    expect(response.code).to eq(200)
  end

  it "should set the requested_url and requested_http_method on the response" do
    response = Typhoeus::RemoteProxyObject.new(lambda {}, @easy)
    expect(response.requested_url).to eq("http://localhost:3001")
    expect(response.requested_http_method).to eq(:get)
  end
  
  it "should call the on_success method with an easy object and proxy to the result of on_success" do
    klass = Class.new do
      def initialize(r)
        @response = r
      end
      
      def blah
        @response.code
      end
    end
    
    k = Typhoeus::RemoteProxyObject.new(lambda {}, @easy, :on_success => lambda {|e| klass.new(e)})
    expect(k.blah).to eq(200)
  end
  
  it "should call the on_failure method with an easy object and proxy to the result of on_failure" do
    klass = Class.new do
      def initialize(r)
        @response = r
      end
      
      def blah
        @response.code
      end
    end
    @easy.url = "http://localhost:3005" #bad port
    k = Typhoeus::RemoteProxyObject.new(lambda {}, @easy, :on_failure => lambda {|e| klass.new(e)})
    expect(k.blah).to eq(0)
  end
end
