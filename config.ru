require 'rubygems'
require 'bundler'

Bundler.require

Honeybadger.configure do |config|
  config.api_key = ENV['HONEYBADGER_API_KEY']
end
 
require './server'

use Honeybadger::Rack
run Server