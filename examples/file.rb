require 'rubygems'
require File.dirname(__FILE__) + '/../lib/xingfus.rb'


response = Xingfus::Request.post(
  "http://video-feed.local",
  :params => {
    :file => File.new("file.rb")
  }
)

puts response.inspect