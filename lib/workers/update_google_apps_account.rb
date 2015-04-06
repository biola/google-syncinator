module Workers
  class UpdateGoogleAppsAccount
    include Sidekiq::Worker

    sidekiq_options retry: false

    def perform(email, first_name, last_name, department, title, privacy, sync_log_id)
      begin
        if GoogleAccount.new(email).update!(first_name, last_name, department, title, privacy)
          TrogdirChangeFinishWorker.perform_async sync_log_id, :create
        end
      rescue StandardError => err
        TrogdirChangeErrorWorker.perform_async sync_log_id, err.message
        Raven.capture_exception(err) if defined? Raven
      end
    end
  end
end
