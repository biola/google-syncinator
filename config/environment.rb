# This file should be included by irb, sidekiq or just about anything else.
# It is the initializer for this project.

require 'bundler'
Bundler.require :default, ENV['RACK_ENV'] || ENV['RAILS_ENV'] || :development

require './lib/google_syncinator'
GoogleSyncinator.initialize!
