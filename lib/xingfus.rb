$LOAD_PATH.unshift(File.dirname(__FILE__)) unless $LOAD_PATH.include?(File.dirname(__FILE__))
$LOAD_PATH.unshift(File.dirname(__FILE__) + "/../ext")

require 'digest/sha2'
require 'xingfus/utils'
require 'xingfus/normalized_header_hash'
require 'xingfus/easy'
require 'xingfus/form'
require 'xingfus/multi'
require 'typhoeus/native'
require 'xingfus/filter'
require 'xingfus/remote_method'
require 'xingfus/remote'
require 'xingfus/remote_proxy_object'
require 'xingfus/response'
require 'xingfus/request'
require 'xingfus/hydra'
require 'xingfus/hydra_mock'
require 'xingfus/version'

module Xingfus
  def self.easy_object_pool
    @easy_objects ||= []
  end

  def self.init_easy_object_pool
    20.times do
      easy_object_pool << Xingfus::Easy.new
    end
  end

  def self.release_easy_object(easy)
    easy.reset
    easy_object_pool << easy
  end

  def self.get_easy_object
    if easy_object_pool.empty?
      Xingfus::Easy.new
    else
      easy_object_pool.pop
    end
  end

  def self.add_easy_request(easy_object)
    Thread.current[:curl_multi] ||= Xingfus::Multi.new
    Thread.current[:curl_multi].add(easy_object)
  end

  def self.perform_easy_requests
    multi = Thread.current[:curl_multi]
    start_time = Time.now
    multi.easy_handles.each do |easy|
      easy.start_time = start_time
    end
    multi.perform
  end
end
