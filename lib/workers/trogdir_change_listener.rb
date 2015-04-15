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
      Log.info "[#{jid}] Starting job"

      response = change_syncs.start.perform
      raise TrogdirAPIError, response.parse['error'] unless response.success?

      hashes = Array(response.parse)
      changes = hashes.map { | hash| TrogdirChange.new(hash) }

      # Keep processing batches until we run out
      changes_found = if changes.any?
        Log.info "[#{jid}] Processing #{changes.length} changes"
        changes.each do |change|
          skipped = true

          begin
            if change.affiliation_added? && !change.university_email_exists?
              email_options = EmailAddressOptions.new(change.affiliations, change.preferred_name, change.first_name, change.middle_name, change.last_name).to_a

              if email_options.any?
                Log.info "[#{jid}] Assigning email address to person #{change.person_uuid}"
                AssignEmailAddress.perform_async(change.person_uuid, email_options, change.sync_log_id)
                skipped = false
              end
            end

            if change.university_email_added? || (change.account_info_updated? && change.university_email_exists?)
              Log.info "[#{jid}] Syncing Google account #{change.university_email} for person #{change.person_uuid}"
              SyncGoogleAppsAccount.perform_async(change.university_email, change.preferred_name, change.last_name, change.title, change.department, change.privacy, change.sync_log_id)
              skipped = false
            end

            # TODO: handle changes to email address with appropriate renaming and aliasing

            if skipped
              Log.info "[#{jid}] No changes needed for person #{change.person_uuid}"
              TrogdirChangeFinishWorker.perform_async change.sync_log_id, :skip
            end
          end
        rescue StandardError => err
          TrogdirChangeErrorWorker.perform_async change.sync_log_id, err.message
          Raven.capture_exception(err) if defined? Raven
        end

        TrogdirChangeListener.perform_async
      end

      Log.info "[#{jid}] Finished job"
      changes_found
    end

    private

    def change_syncs
      Trogdir::APIClient::ChangeSyncs.new
    end
  end
end
