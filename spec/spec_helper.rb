require "rubygems"
require 'json'

path = File.expand_path(File.dirname(__FILE__) + "/../lib/")
$LOAD_PATH.unshift(path) unless $LOAD_PATH.include?(path)

require path + '/xingfus'

RSpec.configure do |config|
end
