source 'https://rubygems.org'

gem 'activesupport'
gem 'blazing'
gem 'google-api-client'
gem 'logging', '~> 1.8' # 2.0 is not compatible with blazing
gem 'mail'
# beta1 fixes this issue https://github.com/railsconfig/rails_config/pull/86
gem 'mongoid'
gem 'mysql2'
gem 'rails_config', '~> 0.5.0.beta1'
gem 'rake'
gem 'sequel'
gem 'sidekiq'
gem 'sidekiq-status'
gem 'sidetiq'
gem 'trogdir_api_client'

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
