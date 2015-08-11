require 'bundler'
Bundler.require :default, ENV['RACK_ENV'] || ENV['RAILS_ENV'] || :development

require './lib/alphabet_syncinator'
AlphabetSyncinator.initialize!
