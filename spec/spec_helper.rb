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

DB = Sequel.connect(Settings.ws.db.to_hash)
unless DB.table_exists?(:email)
  DB.create_table(:email) do
    primary_key :id
    String :idnumber
    String :email
    Integer :primary
    DateTime :expiration_date, default: nil
    DateTime :reusable_date, default: nil
  end
end

RSpec.configure do |config|
  config.include Mongoid::Matchers

  # Clean/Reset Mongoid DB prior to running each test.
  config.before(:each) do
    Mongoid::Sessions.default.collections.select {|c| c.name !~ /system/ }.each(&:drop)
  end
end
