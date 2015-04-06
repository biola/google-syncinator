module Workers
  class TrogdirChangeListener
    include Sidekiq::Worker
    include Sidetiq::Schedulable

    class TrogdirAPIError < StandardError; end

    sidekiq_options retry: false

    recurrence do
      hourly.hour_of_day(*(8..20).to_a).day(:monday, :tuesday, :wednesday, :thursday, :friday)
    end

    def perform
      response = change_syncs.start.perform
      raise TrogdirAPIError, response.parse['error'] unless response.success?

      hashes = Array(response.parse)
      changes = hashes.map { | hash| TrogdirChange.new(hash) }

      # Keep processing batches until we run out
      if changes.any?
        changes.each do |change|
          skipped = true

          if change.affiliation_added? && !change.university_email_exists?
            email_options = EmailAddressOptions.new(change.affiliations, change.preferred_name, change.first_name, change.middle_name, change.last_name).to_a

            if email_options.any?
              AssignEmailAddress.perform_async(change.person_uuid, email_options, change.sync_log_id)
              skipped = false
            end
          end

          if change.university_email_added?
            # TODO: CreateGoogleAppsAccount.perform_async()
            skipped = false
          end

          if change.account_info_updated? && change.university_email_exists?
            SyncGoogleAppsAccount.perform_async(change.email, change.first_name, change.last_name, change.title, change.department, change.privacy, change.sync_log_id)
            skipped = false
          end

          # TODO: handle changes to email address with appropriate renaming and aliasing

          finish! change, :skip if skipped
        end

        SyncPersonalEmails.perform_async
      end
    end

    private

    def finish!(change, action)
      TrogdirChangeFinishWorker.perform_async change.sync_log_id, action
    end

    def change_syncs
      Trogdir::APIClient::ChangeSyncs.new
    end
  end
end
