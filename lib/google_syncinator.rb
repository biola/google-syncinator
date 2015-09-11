# Module for application meta-code, intialization, environment, etc.
module GoogleSyncinator
  # The environment the application is running in. Looks for a RACK_ENV or
  #   RAILS_ENV environment variable, otherwise it's :development by default
  # @return [Symbol]
  def self.environment
    (ENV['RACK_ENV'] || ENV['RAILS_ENV'] || :development).to_sym
  end

  # Initializes everything that is needed for the application to run - settings
  #   databases, workers, etc. Also requires all the needed files and libraries.
  # @return [true]
  def self.initialize!
    ENV['RACK_ENV'] ||= environment.to_s

    RailsConfig.load_and_set_settings('./config/settings.yml', "./config/settings.#{environment}.yml", './config/settings.local.yml')

    ::DB ||= Sequel.connect(Settings.ws.db.to_hash)

    # Use mongoid.yml.example for Travis CI, etc.
    mongoid_yml_path = File.expand_path('../../config/mongoid.yml',  __FILE__)
    mongoid_yml_path = "#{mongoid_yml_path}.example" if !File.exists? mongoid_yml_path
    Mongoid.load! mongoid_yml_path

    if defined? Raven
      Raven.configure do |config|
        config.dsn = Settings.sentry.url
      end
    end

    Turnout.configure do |config|
      config.named_maintenance_file_paths.merge! server: '/tmp/turnout.yml'
      config.default_maintenance_page = Turnout::MaintenancePage::JSON
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

    Mail.defaults do
      delivery_method Settings.email.delivery_method, Settings.email.options.to_hash
    end

    Weary::Adapter::NetHttpAdvanced.timeout = Settings.trogdir.api_timeout

    require 'active_support'
    require 'active_support/core_ext'
    require 'google/api_client'
    require 'grape-kaminari'
    require 'rack/contrib'

    # NOTE: this should be here below the other requires because apparently it
    #   defines it's own Rails module that makes other things think that Rails
    #   is loaded, when it isn't.
    require 'api-auth'

    require './lib/api'
    require './lib/email_address_options'
    require './lib/emails'
    require './lib/google_account'
    require './lib/log'
    require './lib/service_objects'
    require './lib/trogdir_change'
    require './lib/trogdir_person'
    require './lib/unique_email_address'
    require './lib/whitelist'
    require './lib/workers'

    require './lib/mongoid_models/client'
    require './lib/mongoid_models/deprovision_schedule'
    require './lib/mongoid_models/exclusion'
    require './lib/mongoid_models/university_email'

    true
  end

  # Configuration block for the pinglish gem
  # @return [nil]
  def self.pinglish_block
    Proc.new do |ping|
      ping.check :mongodb do
        Mongoid.default_session.command(ping: 1).has_key? 'ok'
      end

      ping.check :mysql do
        DB.run('SELECT 1').nil?
      end

      ping.check :trogdir_api do
        Trogdir::APIClient::People.new.by_id(id: 0).perform.status < 500
      end

      ping.check :google_api, timeout: 10 do
        # Authenticates with the Google API
        GoogleAccount.send(:api)
        true
      end

      ping.check :smtp do
        smtp = Net::SMTP.new(Settings.email.options.address)
        smtp.start
        ok = smtp.started?
        smtp.finish

        ok
      end

      nil
    end
  end
end
