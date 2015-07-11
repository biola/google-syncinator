$:.unshift File.expand_path(File.dirname(__FILE__) + '/../lib')

ENV['RACK_ENV'] = ENV['RAILS_ENV'] = 'test'

require 'bundler'
Bundler.require :default, :test

require 'rspec'

require 'sidekiq/testing'
Sidekiq::Testing.fake!

require 'google_syncinator'
GoogleSyncinator.initialize!

Dir['./spec/support/*.rb'].each { |f| require f }

RSpec.configure do |config|
  config.include Mongoid::Matchers
end
