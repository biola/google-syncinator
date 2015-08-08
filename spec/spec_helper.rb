$:.unshift File.expand_path(File.dirname(__FILE__) + '/../lib')

ENV['RACK_ENV'] = ENV['RAILS_ENV'] = 'test'

require 'bundler'
Bundler.require :default, :test

require 'rspec'
require 'sidekiq/testing'

require 'google_syncinator'
GoogleSyncinator.initialize!

Dir['./spec/support/*.rb'].each { |f| require f }

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

  config.before(:context, type: :feature) do
    Sidekiq::Testing.inline!
  end

  config.before(:context, type: :unit) do
    Sidekiq::Testing.fake!
  end

  config.around(:each) do |example|
    DB.transaction(rollback: :always, auto_savepoint: true) { example.run }
  end

  # Clean/Reset Mongoid DB and MySQL prior to running each test.
  config.before(:each) do
    Mongoid::Sessions.default.collections.select {|c| c.name !~ /system/ }.each(&:drop)
    Sidekiq::Worker.clear_all
  end
end
