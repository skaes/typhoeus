require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe Typhoeus::Easy do
  it "should save easy handles that get added" do
    multi = Typhoeus::Multi.new
    easy = Typhoeus::Easy.new
    easy.url = "http://localhost:3002"
    easy.method = :get

    multi.add(easy)
    expect(multi.easy_handles).to eq([easy])
    multi.perform
    expect(multi.easy_handles).to eq([])
  end
  
  it "should be reusable" do
    easy = Typhoeus::Easy.new
    easy.url = "http://localhost:3002"
    easy.method = :get
    
    multi = Typhoeus::Multi.new
    multi.add(easy)
    multi.perform
    expect(easy.response_code).to eq(200)
    expect(JSON.parse(easy.response_body)["REQUEST_METHOD"]).to eq("GET")
    
    e2 = Typhoeus::Easy.new
    e2.url = "http://localhost:3002"
    e2.method = :post
    multi.add(e2)
    multi.perform
    
    expect(e2.response_code).to eq(200)
    expect(JSON.parse(e2.response_body)["REQUEST_METHOD"]).to eq("POST")
  end
  
  it "should perform easy handles added after the first one runs" do
    easy = Typhoeus::Easy.new
    easy.url = "http://localhost:3002"
    easy.method = :get
    multi = Typhoeus::Multi.new
    multi.add(easy)

    e2 = Typhoeus::Easy.new
    e2.url = "http://localhost:3002"
    e2.method = :post
    easy.on_success do |e|
      multi.add(e2)
    end
    
    multi.perform
    expect(easy.response_code).to eq(200)
    expect(JSON.parse(easy.response_body)["REQUEST_METHOD"]).to eq("GET")
    expect(e2.response_code).to eq(200)
    expect(JSON.parse(e2.response_body)["REQUEST_METHOD"]).to eq("POST")
  end
  
  # it "should do multiple gets" do
    # multi = Typhoeus::Multi.new
    # 
    # handles = []
    # 5.times do |i|
    #   easy = Typhoeus::Easy.new
    #   easy.url = "http://localhost:3002"
    #   easy.method = :get
    #   easy.on_success {|e| puts "get #{i} succeeded"}
    #   easy.on_failure {|e| puts "get #{i} failed with #{e.response_code}"}
    #   handles << easy
    #   multi.add(easy)
    # end
    # 
    # multi.perform
  # end
end
