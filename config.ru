require ::File.expand_path('../config/environment',  __FILE__)

env = ENV['RACK_ENV'] || ENV['RAILS_ENV'] || 'development'

file = File.new("./log/#{env}.log", 'a+')
file.sync = true
use Rack::CommonLogger, file

use Pinglish, &GoogleSyncinator.pinglish_block

run API
