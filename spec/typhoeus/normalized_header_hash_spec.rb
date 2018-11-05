require File.expand_path(File.dirname(__FILE__) + "/../spec_helper")

describe Typhoeus::NormalizedHeaderHash do
  before(:all) do
    @klass = Typhoeus::NormalizedHeaderHash
  end

  it "should normalize keys on assignment" do
    hash = @klass.new
    hash['Content-Type'] = 'text/html'
    expect(hash['content-type']).to eq('text/html')
    expect(hash[:content_type]).to eq('text/html')
    hash['Accepts'] = 'text/javascript'
    expect(hash['accepts']).to eq('text/javascript')
  end

  it "should normalize the keys on instantiation" do
    hash = @klass.new('Content-Type' => 'text/html', :x_http_header => 'foo', 'X-HTTP-USER' => 'bar')
    expect(hash.keys).to match_array(['Content-Type', 'X-Http-Header', 'X-Http-User'])
  end

  it "should merge keys correctly" do
    hash = @klass.new
    hash.merge!('Content-Type' => 'fdsa')
    expect(hash['content-type']).to eq('fdsa')
  end

  it "should allow any casing of keys" do
    hash = @klass.new
    hash['Content-Type'] = 'fdsa'
    expect(hash['content-type']).to eq('fdsa')
    expect(hash['cOnTent-TYPE']).to eq('fdsa')
    expect(hash['Content-Type']).to eq('fdsa')
  end

  it "should support has_key?" do
    hash = @klass.new
    hash['Content-Type'] = 'fdsa'
    expect(hash.has_key?('cOntent-Type')).to eq(true)
  end
end
