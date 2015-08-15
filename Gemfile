source 'https://rubygems.org'

gem 'activesupport'
# NOTE: api-auth seems to define a module called Rails somewhere which causes
#   problems with some Rails hooks in other gems. We'll not require it here, but
#   require it in google_syncinator.rb instead to work around it.
gem 'api-auth', require: false
gem 'blazing'
gem 'google-api-client'
gem 'grape'
gem 'grape-entity'
gem 'grape-kaminari'
gem 'logging', '~> 1.8' # 2.0 is not compatible with blazing
gem 'mail'
gem 'mongoid'
gem 'mysql2'
gem 'oj'
gem 'pinglish'
# NOTE: beta1 fixes this issue https://github.com/railsconfig/rails_config/pull/86
gem 'rails_config', '~> 0.5.0.beta1'
gem 'rack-contrib'
gem 'rake'
gem 'sequel'
gem 'sidekiq'
gem 'sidekiq-status'
gem 'sidetiq'
gem 'trogdir_api_client'
gem 'turnout'

group :development do
  gem 'yard'
  gem 'yard-mongoid'
end

group :development, :test do
  gem 'pry'
  gem 'pry-rescue'
  gem 'pry-stack_explorer'
  gem 'rspec'
end

group :test do
  gem 'mongoid-rspec', '~> 2.1'
end

group :production do
  gem 'sentry-raven'
end
