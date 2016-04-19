module ServiceObjects
  # Runs the appropriate other `ServiceObject`s
  class HandleChange < Base
    # Trogdir SyncLogs only accept one action. This array is ordered by which action
    # should take precedence over the other when multiple actions are performed.
    PRIORITIZED_ACTIONS = [:destroy, :create, :update, :skip]

    # Runs the appropriate service objects for this change
    # @return [Array<Symbol>] a list of actions taken
    def call
      actions = []

      begin
        unless AssignEmailAddress.ignore?(change)
          actions << AssignEmailAddress.new(change).call
          Log.info "Assigning email address to person #{change.person_uuid}"
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

        unless CancelDeprovisioningGoogleAccount.ignore?(change)
          Log.info "Cancel deprovisioning of #{change.university_email} for person #{change.person_uuid}"
          actions << CancelDeprovisioningGoogleAccount.new(change).call
        end

        unless ReprovisionGoogleAccount.ignore?(change)
          Log.info "Begin deprovisioning of #{change.university_email} for person #{change.person_uuid}"
          actions << ReprovisionGoogleAccount.new(change).call
        end

        unless UpdateBiolaID.ignore?(change)
          Log.info "Begin change from #{change.old_id} to #{change.new_id} for person #{change.person_uuid}"
          actions << UpdateBiolaID.new(change).call
        end

        action = most_important_action(actions) || :skip
        Log.info "No changes needed for person #{change.person_uuid}" if actions.empty?
        Workers::Trogdir::ChangeFinish.perform_async change.sync_log_id, action

      rescue StandardError => err
        Workers::Trogdir::ChangeError.perform_async change.sync_log_id, err.message
        Raven.capture_exception(err) if defined? Raven
        raise err
      end

      actions
    end

    # Should this `change` be processed by any of the other ServiceObjects
    # @return [Boolean]
    def ignore?
      [AssignEmailAddress, SyncGoogleAccount, JoinGoogleGroup, LeaveGoogleGroup, DeprovisionGoogleAccount, CancelDeprovisioningGoogleAccount, ReprovisionGoogleAccount, UpdateBiolaID].all? do |klass|
        klass.ignore? change
      end
    end

    private

    # Simple wrapper for the Trogdir API change syncs object
    # @return [Trogdir::APIClient::ChangeSyncs]
    def change_syncs
      Trogdir::APIClient::ChangeSyncs.new
    end

    # Returns the single most important actions
    # @param actions [Array<Symbol>]
    # @return [Symbol]
    def most_important_action(actions)
      PRIORITIZED_ACTIONS.find do |action|
        actions.include? action
      end
    end
  end
end
