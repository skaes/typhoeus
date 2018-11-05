require File.expand_path(File.dirname(__FILE__) + "/../spec_helper")

describe Typhoeus::HydraMock do
  it "should mark all responses as mocks" do
    response = Typhoeus::Response.new(:mock => false)
    expect(response).not_to be_mock

    mock = Typhoeus::HydraMock.new("http://localhost", :get)
    mock.and_return(response)

    expect(mock.response).to be_mock
    expect(response).to be_mock
  end

  describe "stubbing response values" do
    before(:each) do
      @stub = Typhoeus::HydraMock.new('http://localhost:3000', :get)
    end

    describe "with a single response" do
      it "should always return that response" do
        response = Typhoeus::Response.new
        @stub.and_return(response)

        5.times do
          expect(@stub.response).to eq(response)
        end
      end
    end

    describe "with multiple responses" do
      it "should return consecutive responses in the array, then keep returning the last one" do
        responses = []
        3.times do |i|
          responses << Typhoeus::Response.new(:body => "response #{i}")
        end

        # Stub 3 consecutive responses.
        @stub.and_return(responses)

        0.upto(2) do |i|
          expect(@stub.response).to eq(responses[i])
        end

        5.times do
          expect(@stub.response).to eq(responses.last)
        end
      end
    end
  end

  describe "#matches?" do
    describe "basic matching" do
      it "should not match if the HTTP verbs are different" do
        request = Typhoeus::Request.new("http://localhost:3000",
                                        :method => :get)
        mock = Typhoeus::HydraMock.new("http://localhost:3000", :post)
        expect(mock.matches?(request)).to eq(false)
      end
    end

    describe "matching on ports" do
      it "should handle default port 80 sanely" do
        mock = Typhoeus::HydraMock.new('http://www.example.com:80/', :get,
                                       :headers => { 'user-agent' => 'test' })
        request = Typhoeus::Request.new('http://www.example.com/',
                                        :method => :get,
                                        :user_agent => 'test')
        expect(mock.matches?(request)).to eq(true)
      end

      it "should handle default port 443 sanely" do
        mock = Typhoeus::HydraMock.new('https://www.example.com:443/', :get,
                                       :headers => { 'user-agent' => 'test' })
        request = Typhoeus::Request.new('https://www.example.com/',
                                        :method => :get,
                                        :user_agent => 'test')
        expect(mock.matches?(request)).to eq(true)
      end
    end


    describe "any HTTP verb" do
      it "should match any verb" do
        mock = Typhoeus::HydraMock.new("http://localhost:3000", :any,
                                       :headers => { 'user-agent' => 'test' })
        [:get, :post, :delete, :put].each do |verb|
          request = Typhoeus::Request.new("http://localhost:3000",
                                          :method => verb,
                                          :user_agent => 'test')
          expect(mock.matches?(request)).to eq(true)
        end
      end
    end

    describe "header matching" do
      def request(options = {})
        Typhoeus::Request.new("http://localhost:3000", options.merge(:method => :get))
      end

      def hydra_mock(options = {})
        Typhoeus::HydraMock.new("http://localhost:3000", :get, options)
      end

      context 'when no :headers option is given' do
        subject { hydra_mock }

        it "matches regardless of whether or not the request has headers" do
          expect(subject.matches?(request(:headers => nil))).to eq(true)
          expect(subject.matches?(request(:headers => {}))).to eq(true)
          expect(subject.matches?(request(:headers => { 'a' => 'b' }))).to eq(true)
        end
      end

      [nil, {}].each do |value|
        context "for :headers => #{value.inspect}" do
          subject { hydra_mock(:headers => value) }

          it "matches when the request has no headers" do
            expect(subject.matches?(request(:headers => nil))).to eq(true)
            expect(subject.matches?(request(:headers => {}))).to eq(true)
          end

          it "does not match when the request has headers" do
            expect(subject.matches?(request(:headers => { 'a' => 'b' }))).to eq(false)
          end
        end
      end

      context 'for :headers => [a hash]' do
        it 'does not match if the request has no headers' do
          m = hydra_mock(:headers => { 'A' => 'B', 'C' => 'D' })

          expect(m.matches?(request)).to eq(false)
          expect(m.matches?(request(:headers => nil))).to eq(false)
          expect(m.matches?(request(:headers => {}))).to eq(false)
        end

        it 'does not match if the request lacks any of the given headers' do
          expect(hydra_mock(
            :headers => { 'A' => 'B', 'C' => 'D' }
          ).matches?(request(
            :headers => { 'A' => 'B' }
          ))).to eq(false)
        end

        it 'does not match if any of the specified values are different from the request value' do
          expect(hydra_mock(
            :headers => { 'A' => 'B', 'C' => 'D' }
          ).matches?(request(
            :headers => { 'A' => 'B', 'C' => 'E' }
          ))).to eq(false)
        end

        it 'matches if the given hash is exactly equal to the request headers' do
          expect(hydra_mock(
            :headers => { 'A' => 'B', 'C' => 'D' }
          ).matches?(request(
            :headers => { 'A' => 'B', 'C' => 'D' }
          ))).to eq(true)
        end

        it 'matches even if the request has additional headers not specified in the mock' do
          expect(hydra_mock(
            :headers => { 'A' => 'B', 'C' => 'D' }
          ).matches?(request(
            :headers => { 'A' => 'B', 'C' => 'D', 'E' => 'F' }
          ))).to eq(true)
        end

        it 'matches even if the casing of the header keys is different between the mock and request' do
          expect(hydra_mock(
            :headers => { 'A' => 'B', 'c' => 'D' }
          ).matches?(request(
            :headers => { 'a' => 'B', 'C' => 'D' }
          ))).to eq(true)
        end

        it 'matches if the mocked values are regexes and match the request values' do
          expect(hydra_mock(
            :headers => { 'A' => /foo/, }
          ).matches?(request(
            :headers => { 'A' => 'foo bar' }
          ))).to eq(true)
        end

        it 'does not match if the mocked values are regexes and do not match the request values' do
          expect(hydra_mock(
            :headers => { 'A' => /foo/, }
          ).matches?(request(
            :headers => { 'A' => 'bar' }
          ))).to eq(false)
        end

        context 'when a header is specified as an array' do
          it 'matches when the request header has the same array' do
            expect(hydra_mock(
              :headers => { 'Accept' => ['text/html', 'text/plain'] }
            ).matches?(request(
              :headers => { 'Accept' => ['text/html', 'text/plain'] }
            ))).to eq(true)
          end

          it 'matches when the request header is a single value and the mock array has the same value' do
            expect(hydra_mock(
              :headers => { 'Accept' => ['text/html'] }
            ).matches?(request(
              :headers => { 'Accept' => 'text/html' }
            ))).to eq(true)
          end

          it 'matches even when the request header array is ordered differently' do
            expect(hydra_mock(
              :headers => { 'Accept' => ['text/html', 'text/plain'] }
            ).matches?(request(
              :headers => { 'Accept' => ['text/plain', 'text/html'] }
            ))).to eq(true)
          end

          it 'does not match when the request header array lacks a value' do
            expect(hydra_mock(
              :headers => { 'Accept' => ['text/html', 'text/plain'] }
            ).matches?(request(
              :headers => { 'Accept' => ['text/plain'] }
            ))).to eq(false)
          end

          it 'does not match when the request header array has an extra value' do
            expect(hydra_mock(
              :headers => { 'Accept' => ['text/html', 'text/plain'] }
            ).matches?(request(
              :headers => { 'Accept' => ['text/html', 'text/plain', 'application/xml'] }
            ))).to eq(false)
          end

          it 'does not match when the request header is not an array' do
            expect(hydra_mock(
              :headers => { 'Accept' => ['text/html', 'text/plain'] }
            ).matches?(request(
              :headers => { 'Accept' => 'text/html' }
            ))).to eq(false)
          end
        end
      end
    end

    describe "post body matching" do
      it "should not bother matching on body if we don't turn the option on" do
        request = Typhoeus::Request.new("http://localhost:3000",
                                        :method => :get,
                                        :user_agent => 'test',
                                        :body => "fdsafdsa")
        mock = Typhoeus::HydraMock.new("http://localhost:3000", :get,
                                       :headers => { 'user-agent' => 'test' })
        expect(mock.matches?(request)).to eq(true)
      end

      it "should match nil correctly" do
        request = Typhoeus::Request.new("http://localhost:3000",
                                        :method => :get,
                                        :body => "fdsafdsa")
        mock = Typhoeus::HydraMock.new("http://localhost:3000", :get,
                                       :body => nil)
        expect(mock.matches?(request)).to eq(false)
      end

      it "should not match if the bodies do not match" do
        request = Typhoeus::Request.new("http://localhost:3000",
                                        :method => :get,
                                        :body => "ffdsadsafdsa")
        mock = Typhoeus::HydraMock.new("http://localhost:3000", :get,
                                       :body => 'fdsafdsa')
        expect(mock.matches?(request)).to eq(false)
      end

      it "should match on optional body parameter" do
        request = Typhoeus::Request.new("http://localhost:3000",
                                        :method => :get,
                                        :user_agent => 'test',
                                        :body => "fdsafdsa")
        mock = Typhoeus::HydraMock.new("http://localhost:3000", :get,
                                       :body => 'fdsafdsa',
                                       :headers => {
                                         'User-Agent' => 'test'
                                       })
        expect(mock.matches?(request)).to eq(true)
      end

      it "should regex match" do
        request = Typhoeus::Request.new("http://localhost:3000/whatever/fdsa",
                                        :method => :get,
                                        :user_agent => 'test')
        mock = Typhoeus::HydraMock.new(/fdsa/, :get,
                                       :headers => { 'user-agent' => 'test' })
        expect(mock.matches?(request)).to eq(true)
      end
    end
  end
end

