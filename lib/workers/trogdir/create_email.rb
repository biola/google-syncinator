module Workers
  module Trogdir
    # Sidekiq worker that creates an email record in Trogdir
    class CreateEmail
      include Sidekiq::Worker

      # The type of email to create
      EMAIL_TYPE = :university

      # Whether or not the created email should be primary
      MAKE_EMAIL_PRIMARY = true

      # Create an email record in Trogdir
      # @param uuid [String] UUID of the person who will own the email address
      # @param email [String] email address to create
      # @return [nil]
      def perform(uuid, email)
        if !Settings.dry_run?
          response = ::Trogdir::APIClient::Emails.new.create(uuid: uuid, address: email, type: EMAIL_TYPE, primary: MAKE_EMAIL_PRIMARY).perform
          raise TrogdirAPIError, response.parse['error'] unless response.success?
        end

        Log.info "Created Trogdir email for #{uuid} with address: #{email}, type: #{EMAIL_TYPE}, primary: #{MAKE_EMAIL_PRIMARY}"

        nil
      end
    end
  end
end
