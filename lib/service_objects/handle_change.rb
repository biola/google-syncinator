module ServiceObjects
  class HandleChange < Base
    # TODO: handle changes to email address with appropriate renaming and aliasing
    # TODO: limit to emails with @biola.edu domain
    def call
      actions = []

      begin
        unless AssignEmailAddress.ignore?(change)
          if assign_action = AssignEmailAddress.new(change).call
            Log.info "Assigning email address to person #{change.person_uuid}"
            actions << assign_action
          end
        end

        unless SyncGoogleAccount.ignore?(change)
          Log.info "Syncing Google account #{change.university_email} for person #{change.person_uuid}"
          actions << SyncGoogleAccount.new(change).call
        end

        action = actions.first || :skip
        Log.info "No changes needed for person #{change.person_uuid}" if actions.empty?
        Workers::ChangeFinish.perform_async change.sync_log_id, action

      rescue StandardError => err
        Workers::ChangeError.perform_async change.sync_log_id, err.message
        Raven.capture_exception(err) if defined? Raven
      end
    end

    def ignore?(change)
      AssignEmailAddress.ignore?(change) && SyncGoogleAccount.ignore?(change)
    end

    private

    def change_syncs
      Trogdir::APIClient::ChangeSyncs.new
    end
  end
end
