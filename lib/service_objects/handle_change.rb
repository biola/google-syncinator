module ServiceObjects
  # Runs the appropriate other `ServiceObject`s
  class HandleChange < Base
    # TODO: limit to emails with @biola.edu domain

    # Runs the appropriate service objects for this change
    # @return [Array<Symbol>] a list of actions taken
    def call
      actions = []

      begin
        unless AssignEmailAddress.ignore?(change)
          actions << AssignEmailAddress.new(change).call
          Log.info "Assigning email address to person #{change.person_uuid}"
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

      actions
    end

    # Should this `change` be processed by any of the other ServiceObjects
    # @return [Boolean]
    def ignore?
      [AssignEmailAddress, SyncGoogleAccount, UpdateEmailAddress, JoinGoogleGroup, LeaveGoogleGroup, DeprovisionGoogleAccount, ReprovisionGoogleAccount].all? do |klass|
        klass.ignore? change
      end
    end

    private

    # Simple wrapper for the Trogdir API change syncs object
    # @return [Trogdir::APIClient::ChangeSyncs]
    def change_syncs
      Trogdir::APIClient::ChangeSyncs.new
    end
  end
end
