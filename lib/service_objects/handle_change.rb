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
          Log.info "Updating Alphabet account email (#{change.university_email}) for person #{change.person_uuid}"
          actions << UpdateEmailAddress.new(change).call
        end

        unless SyncAlphabetAccount.ignore?(change)
          Log.info "Syncing Alphabet account #{change.university_email} for person #{change.person_uuid}"
          actions << SyncAlphabetAccount.new(change).call
        end

        unless JoinAlphabetGroup.ignore?(change)
          Log.info "Joining Alphabet group(s) #{Whitelist.filter(change.joined_groups).to_sentence} for person #{change.person_uuid}"
          actions << JoinAlphabetGroup.new(change).call
        end

        unless LeaveAlphabetGroup.ignore?(change)
          Log.info "Leaving Alphabet group(s) #{Whitelist.filter(change.left_groups).to_sentence} for person #{change.person_uuid}"
          actions << LeaveAlphabetGroup.new(change).call
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
      AssignEmailAddress.ignore?(change) && SyncAlphabetAccount.ignore?(change) && UpdateEmailAddress.ignore?(change) && JoinAlphabetGroup.ignore?(change) && LeaveAlphabetGroup.ignore?(change)
    end

    private

    def change_syncs
      Trogdir::APIClient::ChangeSyncs.new
    end
  end
end
