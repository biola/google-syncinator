module Workers
  class CreateTrogdirEmail
    include Sidekiq::Worker

    EMAIL_TYPE = :university
    MAKE_EMAIL_PRIMARY = true

    def perform(uuid, email)
      if !Settings.dry_run?
        response = Trogdir::APIClient::Emails.new.create(uuid: uuid, address: email, type: EMAIL_TYPE, primary: MAKE_EMAIL_PRIMARY).perform
        raise TrogdirAPIError, response.parse['error'] unless response.success?
      end

      Log.info "Created Trogdir email for #{uuid} with address: #{email}, type: #{EMAIL_TYPE}, primary: #{MAKE_EMAIL_PRIMARY}"
    end
  end
end
