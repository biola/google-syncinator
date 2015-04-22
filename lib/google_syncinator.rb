module GoogleSyncinator
  def self.initialize!
    env = ENV['RACK_ENV'] || ENV['RAILS_ENV'] || :development
    ENV['RACK_ENV'] ||= env.to_s

    RailsConfig.load_and_set_settings('./config/settings.yml', "./config/settings.#{env}.yml", './config/settings.local.yml')

    if defined? Raven
      Raven.configure do |config|
        config.dsn = Settings.sentry.url
      end
    end

    Sidekiq.configure_server do |config|
      config.redis = { url: Settings.redis.url, namespace: 'google-syncinator' }
    end

    Sidekiq.configure_client do |config|
      config.redis = { url: Settings.redis.url, namespace: 'google-syncinator' }
    end

    TrogdirAPIClient.configure do |config|
      config.scheme = Settings.trogdir.scheme
      config.host = Settings.trogdir.host
      config.port = Settings.trogdir.port
      config.script_name = Settings.trogdir.script_name
      config.version = Settings.trogdir.version
      config.access_id = Settings.trogdir.access_id
      config.secret_key = Settings.trogdir.secret_key
    end

    Weary::Adapter::NetHttpAdvanced.timeout = Settings.trogdir.api_timeout

    require 'google/api_client'

    require './lib/email_address_options'
    require './lib/google_account'
    require './lib/log'
    require './lib/service_objects'
    require './lib/trogdir_change'
    require './lib/trogdir_person'
    require './lib/unique_email_address'
    require './lib/whitelist'
    require './lib/workers'

    true
  end
end
