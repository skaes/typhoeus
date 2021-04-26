require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe Xingfus::Easy do
  it "should save easy handles that get added" do
    multi = Xingfus::Multi.new
    easy = Xingfus::Easy.new
    easy.url = "http://localhost:3002"
    easy.method = :get

    multi.add(easy)
    multi.easy_handles.should == [easy]
    multi.perform
    multi.easy_handles.should == []
  end
  
  it "should be reusable" do
    easy = Xingfus::Easy.new
    easy.url = "http://localhost:3002"
    easy.method = :get
    
    multi = Xingfus::Multi.new
    multi.add(easy)
    multi.perform
    easy.response_code.should == 200
    JSON.parse(easy.response_body)["REQUEST_METHOD"].should == "GET"
    
    e2 = Xingfus::Easy.new
    e2.url = "http://localhost:3002"
    e2.method = :post
    multi.add(e2)
    multi.perform
    
    e2.response_code.should == 200
    JSON.parse(e2.response_body)["REQUEST_METHOD"].should == "POST"
  end
  
  it "should perform easy handles added after the first one runs" do
    easy = Xingfus::Easy.new
    easy.url = "http://localhost:3002"
    easy.method = :get
    multi = Xingfus::Multi.new
    multi.add(easy)

    e2 = Xingfus::Easy.new
    e2.url = "http://localhost:3002"
    e2.method = :post
    easy.on_success do |e|
      multi.add(e2)
    end
    
    multi.perform
    easy.response_code.should == 200
    JSON.parse(easy.response_body)["REQUEST_METHOD"].should == "GET"
    e2.response_code.should == 200
    JSON.parse(e2.response_body)["REQUEST_METHOD"].should == "POST"
  end
  
  # it "should do multiple gets" do
    # multi = Xingfus::Multi.new
    # 
    # handles = []
    # 5.times do |i|
    #   easy = Xingfus::Easy.new
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
