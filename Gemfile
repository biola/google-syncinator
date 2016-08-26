source 'https://rubygems.org'

gem 'activesupport'
# NOTE: api-auth seems to define a module called Rails somewhere which causes
#   problems with some Rails hooks in other gems. We'll not require it here, but
#   require it in google_syncinator.rb instead to work around it.
gem 'api-auth', require: false
gem 'google-api-client', '~> 0.9'
gem 'grape'
gem 'grape-entity'
gem 'grape-kaminari'
gem 'logging', '~> 2.0' 
gem 'mail'
gem 'mongoid', '~> 5.1'
gem 'mysql2'
gem 'oj'
gem 'pinglish'
gem 'puma'
# NOTE: beta1 fixes this issue https://github.com/railsconfig/rails_config/pull/86
gem 'rails_config', '~> 0.5.0.beta1'
gem 'rack-contrib'
gem 'rake'
gem 'sequel'
gem 'sidekiq'
gem 'sidekiq-status'
gem 'sidekiq-cron'
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
  gem 'factory_girl'
  gem 'faker'
  gem 'mongoid-rspec', '~> 3.0'
end

group :production do
  gem 'sentry-raven'
end
