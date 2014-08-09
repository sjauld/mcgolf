require 'rubygems'
require 'bundler'

Bundler.require
use Rack::Deflater

require './myapp'
run McGolf.new
