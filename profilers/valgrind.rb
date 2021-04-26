#!/usr/bin/env ruby
# go to ext/xingfus and run ruby extconf.rb && make before running
# this.

$LOAD_PATH.unshift(File.dirname(__FILE__) + "/../ext")
require File.dirname(__FILE__) + "/../lib/xingfus"

klass = Class.new { include Xingfus }

loops = ENV['LOOPS'].to_i
url = ARGV.first || (raise "requires URL!")

loops.times do |i|
  puts "On loop #{i}" if i % 10 == 0
  results = []
  5.times do
    results << klass.get(url)
  end
 
  # fire requests
  results[0].code
end

puts "Ran #{loops} loops on #{url}!"
