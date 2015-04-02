module Workers
  class AssignEmailAddress
    include Sidekiq::Worker

    class TrogdirAPIError < StandardError; end

    EMAIL_TYPE = :university
    MAKE_EMAIL_PRIMARY = true

    sidekiq_options retry: false

    def perform(person_uuid, email_options, sync_log_id)
      begin
        unique_email = UniqueEmailAddress.new(email_options).best
        full_unique_email = GoogleAccount.full_email(unique_email)

        response = Trogdir::APIClient::Emails.new.create(uuid: person_uuid, address: full_unique_email, type: EMAIL_TYPE, primary: MAKE_EMAIL_PRIMARY).perform
        if response.success?
          TrogdirChangeFinishWorker.perform_async sync_log_id, :create
        else
          error_message = response.parse['error']
          TrogdirChangeErrorWorker.perform_async sync_log_id, error_message
          Raven.capture_message(error_message) if defined? Raven
        end
      rescue StandardError => err
        TrogdirChangeErrorWorker.perform_async sync_log_id, err.message
        Raven.capture_exception(err) if defined? Raven
      end
    end
  end
end
