require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe Typhoeus::Request do
  describe "#inspect" do
    before(:each) do
      @request = Typhoeus::Request.new('http://www.google.com/',
                                       :body => "a=1&b=2",
                                       :params => { :c => 'ok' },
                                       :method => :get,
                                       :headers => { 'Content-Type' => 'text/html' })
    end

    it "should dump out the URI" do
      expect(@request.inspect).to match(/http:\/\/www\.google\.com/)
    end

    it "should dump out the body" do
      expect(@request.inspect).to match(/a=1&b=2/)
    end

    it "should dump params" do
      expect(@request.inspect).to match(/:c\s*=>\s*"ok"/)
    end

    it "should dump the method" do
      expect(@request.inspect).to match(/:get/)
    end

    it "should dump out headers" do
      expect(@request.inspect).to match(/"Content-Type"\s*=>\s*"text\/html"/)
    end
  end

  describe "#localhost?" do
    %w(localhost 127.0.0.1 0.0.0.0).each do |host|
      it "should be true for the #{host} host" do
        req = Typhoeus::Request.new("http://#{host}")
        expect(req).to be_localhost
      end
    end

    it "should be false for other domains" do
      req = Typhoeus::Request.new("http://google.com")
      expect(req).not_to be_localhost
    end
  end

  describe "#params_string" do
    it "should dump a sorted string" do
      request = Typhoeus::Request.new(
        "http://google.com",
        :params => {
          'b' => 'fdsa',
          'a' => 'jlk',
          'c' => '789'
        }
      )

      expect(request.params_string).to eq("a=jlk&b=fdsa&c=789")
    end

    it "should accept symboled keys" do
      request = Typhoeus::Request.new('http://google.com',
                                      :params => {
                                        :b => 'fdsa',
                                        :a => 'jlk',
                                        :c => '789'
                                      })
      expect(request.params_string).to eq("a=jlk&b=fdsa&c=789")
    end

    it "should translate params with values that are arrays to the proper format" do
      request = Typhoeus::Request.new('http://google.com',
                                      :params => {
                                        :a => ['789','2434']
                                      })
      expect(request.params_string).to eq("a=789&a=2434")
    end

    it "should allow the newer bracket notation for array params" do
      request = Typhoeus::Request.new('http://google.com',
                                      :params => {
                                        "a[]" => ['789','2434']
                                      })
      expect(request.params_string).to eq("a%5B%5D=789&a%5B%5D=2434")
    end

    it "should nest arrays in hashes" do
      request = Typhoeus::Request.new('http://google.com',
                                      :params => {
                                        :a => { :b => { :c => ['d','e'] } }
                                      })
      expect(request.params_string).to eq("a%5Bb%5D%5Bc%5D=d&a%5Bb%5D%5Bc%5D=e")
    end

    it "should translate nested params correctly" do
      request = Typhoeus::Request.new('http://google.com',
                                      :params => {
                                        :a => { :b => { :c => 'd' } }
                                      })
      expect(request.params_string).to eq("a%5Bb%5D%5Bc%5D=d")
    end
  end

  describe "quick request methods" do
    it "can run a GET synchronously" do
      response = Typhoeus::Request.get("http://localhost:3000", :params => {:q => "hi"}, :headers => {:foo => "bar"})
      expect(response.code).to eq(200)
      expect(JSON.parse(response.body)["REQUEST_METHOD"]).to eq("GET")
    end

    it "can run a POST synchronously" do
      response = Typhoeus::Request.post("http://localhost:3000", :params => {:q => { :a => "hi" } }, :headers => {:foo => "bar"})
      expect(response.code).to eq(200)
      json = JSON.parse(response.body)
      expect(json["REQUEST_METHOD"]).to eq("POST")
      expect(json["rack.request.form_hash"]["q"]["a"]).to eq("hi")
    end

    it "can run a PUT synchronously" do
      response = Typhoeus::Request.put("http://localhost:3000", :params => {:q => "hi"}, :headers => {:foo => "bar"})
      expect(response.code).to eq(200)
      expect(JSON.parse(response.body)["REQUEST_METHOD"]).to eq("PUT")
    end

    it "can run a DELETE synchronously" do
      response = Typhoeus::Request.delete("http://localhost:3000", :params => {:q => "hi"}, :headers => {:foo => "bar"})
      expect(response.code).to eq(200)
      expect(JSON.parse(response.body)["REQUEST_METHOD"]).to eq("DELETE")
    end
  end

  it "takes url as the first argument" do
    expect(Typhoeus::Request.new("http://localhost:3000").url).to eq("http://localhost:3000")
  end

  it "should parse the host from the url" do
    expect(Typhoeus::Request.new("http://localhost:3000/whatever?hi=foo").host).to eq("http://localhost:3000")
    expect(Typhoeus::Request.new("http://localhost:3000?hi=foo").host).to eq("http://localhost:3000")
    expect(Typhoeus::Request.new("http://localhost:3000").host).to eq("http://localhost:3000")
  end

  it "takes method as an option" do
    expect(Typhoeus::Request.new("http://localhost:3000", :method => :get).method).to eq(:get)
  end

  it "takes headers as an option" do
    headers = {:foo => :bar}
    request = Typhoeus::Request.new("http://localhost:3000", :headers => headers)
    expect(request.headers).to eq(headers)
  end

  it "takes params as an option and adds them to the url" do
    expect(Typhoeus::Request.new("http://localhost:3000", :params => {:foo => "bar"}).url).to eq("http://localhost:3000?foo=bar")
  end

  it "takes request body as an option" do
    expect(Typhoeus::Request.new("http://localhost:3000", :body => "whatever").body).to eq("whatever")
  end

  it "takes timeout as an option" do
    expect(Typhoeus::Request.new("http://localhost:3000", :timeout => 10).timeout).to eq(10)
  end

  it "takes cache_timeout as an option" do
    expect(Typhoeus::Request.new("http://localhost:3000", :cache_timeout => 60).cache_timeout).to eq(60)
  end

  it "takes follow_location as an option" do
    expect(Typhoeus::Request.new("http://localhost:3000", :follow_location => true).follow_location).to eq(true)
  end

  it "takes max_redirects as an option" do
    expect(Typhoeus::Request.new("http://localhost:3000", :max_redirects => 10).max_redirects).to eq(10)
  end

  it "has the associated response object" do
    request = Typhoeus::Request.new("http://localhost:3000")
    request.response = :foo
    expect(request.response).to eq(:foo)
  end

  it "has an on_complete handler that is called when the request is completed" do
    request = Typhoeus::Request.new("http://localhost:3000")
    foo = nil
    request.on_complete do |response|
      foo = response
    end
    request.response = :bar
    request.call_handlers
    expect(foo).to eq(:bar)
  end

  it "has an on_complete setter" do
    foo = nil
    proc = Proc.new {|response| foo = response}
    request = Typhoeus::Request.new("http://localhost:3000")
    request.on_complete = proc
    request.response = :bar
    request.call_handlers
    expect(foo).to eq(:bar)
  end

  it "stores the handled response that is the return value from the on_complete block" do
    request = Typhoeus::Request.new("http://localhost:3000")
    request.on_complete do |response|
      "handled"
    end
    request.response = :bar
    request.call_handlers
    expect(request.handled_response).to eq("handled")
  end

  it "has an after_complete handler that recieves what on_complete returns" do
    request = Typhoeus::Request.new("http://localhost:3000")
    request.on_complete do |response|
      "handled"
    end
    good = nil
    request.after_complete do |object|
      good = object == "handled"
    end
    request.call_handlers
    expect(good).to eq(true)
  end

  it "has an after_complete setter" do
    request = Typhoeus::Request.new("http://localhost:3000")
    request.on_complete do |response|
      "handled"
    end
    good = nil
    proc = Proc.new {|object| good = object == "handled"}
    request.after_complete = proc

    request.call_handlers
    expect(good).to eq(true)
  end

  describe "time info" do
    it "should have time" do
      response = Typhoeus::Request.get("http://localhost:3000")
      expect(response.time).to be > 0
    end

    it "should have connect time" do
      response = Typhoeus::Request.get("http://localhost:3000")
      expect(response.connect_time).to be > 0
    end

    it "should have app connect time" do
      response = Typhoeus::Request.get("http://localhost:3000")
      expect(response.app_connect_time).to  be > 0
    end

    it "should have start transfer time" do
      response = Typhoeus::Request.get("http://localhost:3000")
      expect(response.start_transfer_time).to  be > 0
    end

    it "should have pre-transfer time" do
      response = Typhoeus::Request.get("http://localhost:3000")
      expect(response.pretransfer_time).to  be > 0
    end

  end

  describe "performed" do
    it "should initially respond with false" do
      request = Typhoeus::Request.new("http://localhost:3000")
      expect(request.performed?).to eq(false)
    end
  end

  describe "authentication" do

    it "should allow to set username and password" do
      auth = { :username => 'foo', :password => 'bar' }
      e = Typhoeus::Request.get(
        "http://localhost:3001/auth_basic/#{auth[:username]}/#{auth[:password]}",
        auth
      )
      expect(e.code).to eq(200)
    end

    it "should allow to set authentication method" do
      auth = {
        :username => 'username',
        :password => 'password',
        :auth_method => :ntlm
      }
      e = Typhoeus::Request.get(
        "http://localhost:3001/auth_ntlm",
        auth
      )
      expect(e.code).to eq(200)
    end

  end

  describe "retry" do
    it "should take a retry option"
    it "should count the number of times a request has failed"
  end

end
