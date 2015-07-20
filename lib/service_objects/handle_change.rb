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

        unless UpdateEmailAddress.ignore?(change)
          Log.info "Updating Google account email (#{change.university_email}) for person #{change.person_uuid}"
          actions << UpdateEmailAddress.new(change).call
        end

        unless SyncGoogleAccount.ignore?(change)
          Log.info "Syncing Google account #{change.university_email} for person #{change.person_uuid}"
          actions << SyncGoogleAccount.new(change).call
        end

        unless JoinGoogleGroup.ignore?(change)
          Log.info "Joining Google group(s) #{Whitelist.filter(change.joined_groups).to_sentence} for person #{change.person_uuid}"
          actions << JoinGoogleGroup.new(change).call
        end

        unless LeaveGoogleGroup.ignore?(change)
          Log.info "Leaving Google group(s) #{Whitelist.filter(change.left_groups).to_sentence} for person #{change.person_uuid}"
          actions << LeaveGoogleGroup.new(change).call
        end

        unless DeprovisionGoogleAccount.ignore?(change)
          Log.info "Begin deprovisioning of #{change.university_email} for person #{change.person_uuid}"
          actions << DeprovisionGoogleAccount.new(change).call
        end

        unless ReprovisionGoogleAccount.ignore?(change)
          Log.info "Begin deprovisioning of #{change.university_email} for person #{change.person_uuid}"
          actions << ReprovisionGoogleAccount.new(change).call
        end

        action = actions.first || :skip
        Log.info "No changes needed for person #{change.person_uuid}" if actions.empty?
        Workers::ChangeFinish.perform_async change.sync_log_id, action

      rescue StandardError => err
        Workers::ChangeError.perform_async change.sync_log_id, err.message
        Raven.capture_exception(err) if defined? Raven
        raise err
      end
    end

    def ignore?
      AssignEmailAddress.ignore?(change) && SyncGoogleAccount.ignore?(change) && UpdateEmailAddress.ignore?(change) && JoinGoogleGroup.ignore?(change) && LeaveGoogleGroup.ignore?(change)
    end

    private

    def change_syncs
      Trogdir::APIClient::ChangeSyncs.new
    end
  end
end
