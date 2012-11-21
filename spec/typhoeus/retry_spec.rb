require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

# some of these tests assume that you have some local services running.
# ruby spec/servers/app.rb -p 3000
# ruby spec/servers/app.rb -p 3001
# ruby spec/servers/app.rb -p 3002

def all_methods;       [:get, :head, :post, :put, :delete]; end
def retryable_methods; [:get]; end
def oneshot_methods;   all_methods - retryable_methods; end

describe Typhoeus::Request do
  describe '#on_retry' do
    it 'should set the @on_retry to the supplied block' do
      some_value = false
      request = Typhoeus::Request.new('url')
      request.on_retry{ some_value = true }
      request.instance_eval{ @on_retry }.should be_a_kind_of(Proc)
      request.instance_eval{ @on_retry }.call
      some_value.should == true
    end
  end

  describe '#on_retry=' do
    it 'should set the @on_retry to the supplied proc' do
      some_value = false
      request = Typhoeus::Request.new('url')
      retry_proc = proc{ some_value = true }
      request.on_retry = retry_proc
      request.instance_eval{ @on_retry }.should == retry_proc
    end
  end

  describe '#call_retry_handler' do
    it 'should call the on_retry handler' do
      some_value = false
      request = Typhoeus::Request.new('url')
      request.on_retry{ some_value = true }
      request.call_retry_handler
      some_value.should == true
    end
  end
end

describe Typhoeus::Hydra do
  describe '#retry_codes' do
    it 'should be empty by default' do
      Typhoeus::Hydra.new.retry_codes.should == []
    end

    it 'should reflect the value of @retry_codes' do
      hydra = Typhoeus::Hydra.new
      hydra.instance_eval{@retry_codes = [503, 504]}
      hydra.retry_codes.should == [503, 504]
    end
  end

  describe '.new' do
    it 'should set the retry_codes with the :retry_codes option' do
      Typhoeus::Hydra.new(:retry_codes => [505, 506]).retry_codes.should == [505, 506]
    end
  end

  describe '#disable_retry' do
    it 'should reset the retry codes to []' do
      hydra = Typhoeus::Hydra.new(:retry_codes => [507, 508])
      hydra.disable_retry

      hydra.retry_codes.should == []
    end
  end

  describe '#retry_codes=' do
    it 'should set the retry codes to based on numeric parameters' do
      hydra = Typhoeus::Hydra.new
      hydra.retry_codes = [509, 510]

      hydra.retry_codes.should == [509, 510]
    end
  end

  describe 'retry' do
    before(:each) do
      @request_timeout = 100
      Typhoeus::Hydra.allow_net_connect = true
      @hydra = Typhoeus::Hydra.new :max_concurrency => 1
      @hydra.enable_memoization
      @cache = {}
      @hydra.cache_getter do |request|
        @cache[request.object_id]
      end

      @hydra.cache_setter do |request|
        raise 'should get here'
        if :get == request.method
          [503, 504].should_not include(request.response.code)
        end
        @cache[request.object_id] = request.response
      end

      @flaky_prefix = "http://localhost:3000/flaky"
    end

    after(:each) do
      # clear the queue in case anything went wrong
      @hydra.run
    end

    describe 'with no retry configured' do
      before(:each) do
        @hydra.disable_retry
      end

      it 'calls should not be retried' do
        Typhoeus::Request.get("#{@flaky_prefix}/set?codes=503,200")
        response = Typhoeus::Request.get("#{@flaky_prefix}?sanity-server-flip")
        response.code.should == 503

        response = Typhoeus::Request.get("#{@flaky_prefix}?sanity-server-flip")
        response.code.should == 200
      end
    end

    describe 'with 503 and 504 configured' do
      before(:each) do
        @hydra.retry_codes = [503, 504]
      end

      describe 'server sanity check' do
        describe '/flaky' do
          it "should return 503 and then 200 for too successive GETs" do
            Typhoeus::Request.get("#{@flaky_prefix}/set?codes=503,200")
            response = Typhoeus::Request.get("#{@flaky_prefix}?sanity-server-flip",
                                             :retry => false)
            response.code.should == 503

            response = Typhoeus::Request.get("#{@flaky_prefix}?sanity-server-flip",
                                             :retry => false)
            response.code.should == 200
          end

          it "it should return 503 multiple times if needed" do
            Typhoeus::Request.get("#{@flaky_prefix}/set?codes=503,503,200")

            response = Typhoeus::Request.get("#{@flaky_prefix}?sanity-server-list",
                                             :retry => false)
            response.code.should == 503

            response = Typhoeus::Request.get("#{@flaky_prefix}?sanity-server-list",
                                             :retry => false)
            response.code.should == 503

            response = Typhoeus::Request.get("#{@flaky_prefix}?sanity-server-list",
                                             :retry => false)
            response.code.should == 200
          end
        end
      end

      describe 'single request' do
        [:enable_memoization, :disable_memoization].each do |memoization_state|
          retryable_methods.each do |method|
            [503, 504].each do |code|
              it "of type #{method} with #{code} should retry request" do
                retry_count = 0
                Typhoeus::Request.get("#{@flaky_prefix}/set?codes=#{code},200")
                request = Typhoeus::Request.new("#{@flaky_prefix}?single-#{code}-success",
                                                :method => method)
                request.on_retry { retry_count += 1 }
                request.cache_timeout = @cache_timeout
                @hydra.queue request
                @hydra.run

                request.response.code.should == 200
                retry_count.should == 1
              end

              it "should result in exception with multiple #{method} yielding #{code} responses" do
                Typhoeus::Request.send(method, "#{@flaky_prefix}/set?codes=#{code},#{code},200")

                request = Typhoeus::Request.new("#{@flaky_prefix}?#{code}-multiple-times-fails",
                                                :method => method)
                @hydra.queue request
                @hydra.run

                request.response.code.should == code
              end
            end
          end
        end

        # TODO: check that 503 is not cached
      end

      describe 'two requests to the same URL with seperate callbacks' do
        [:enable_memoization, :disable_memoization].each do |memoization_state|
          retryable_methods.each do |method|
            [503, 504].each do |code|
              it "#{method} with a single #{code} should be retried (#{memoization_state})" do
                Typhoeus::Request.get("#{@flaky_prefix}/set?codes=503,200")
                @hydra.send(memoization_state)
                callback_count = 0
                retry_count = 0
                request1 = Typhoeus::Request.new("#{@flaky_prefix}?multi-request",
                                                 :method => method)
                request1.on_complete { callback_count += 1 }
                request1.on_retry { retry_count += 1 }
                request1.cache_timeout = @cache_timeout
                request2 = Typhoeus::Request.new("#{@flaky_prefix}?multi-request",
                                                 :method => method)
                request2.on_complete { callback_count += 1 }
                request2.on_retry { retry_count += 1 }
                request1.cache_timeout = @cache_timeout
                @hydra.queue request1
                @hydra.queue request2
                @hydra.run
                callback_count.should == 2
                retry_count.should == 1
                request1.response.code.should == 200
                request2.response.code.should == 200
              end
            end
          end
        end
      end

      describe 'non GET requests with 503 and 504 response codes' do
        [:enable_memoization, :disable_memoization].each do |memoization_state|
          oneshot_methods.each do |method|
            [503, 504].each do |code|
              it "#{method} with #{code} response should not be retried (#{memoization_state})" do
                retry_count = 0
                @hydra.send(memoization_state)
                Typhoeus::Request.get("#{@flaky_prefix}/set?codes=#{code},200")
                # FIXME: why does the test server hang on PUTs with body content?
                request = Typhoeus::Request.new(
                  "#{@flaky_prefix}?multi-#{code}-request",
                  :params => {:q => "hi"},
                  :method => method
                )
                request.on_retry{ retry_count += 1 }
                request.cache_timeout = @cache_timeout
                @hydra.queue request

                @hydra.run

                request.response.code.should == code
                retry_count.should == 0
              end
            end
          end
        end
      end
    end
  end
end


