module ServiceObjects
  # Initiate an email deprovision process by scheduling notices of closure,
  #   notices of inactivity, suspensions and deletions depending on the users
  #   affiliations and account acctivity
  class DeprovisionGoogleAccount < Base
    # Determine what sort of deprovisioning should happen and schedule it
    # @return [Symbol] the action taken
    def call
      # If the email address was recently created and is in it's protection period,
      # then schedule deprovisioning for the end of the protected period
      if account_email.protected?
        # Add 5 minutes to be sure we're past the protection time
        # We won't schedule this during a dry run because even though it would be safe to do now, dry_run could be off when it actually runs
        Workers::DeprovisionGoogleAccount.perform_at(account_email.protected_until + 300, change.hash) if Enabled.write?
        Log.info "Schedule deprovisioning of #{change.person_uuid}/#{change.university_email} for #{account_email.protected_until + 300}"
        return :nothing
      end


      # Not allowed to have an email?
      if !EmailAddressOptions.allowed?(change.affiliations)
        activity = google_account.never_logged_in? ? :never_active : :active

        schedule_actions!(
          Workers::Deprovisioning.schedule_for(account_email, activity, false),
          DeprovisionSchedule::LOST_AFFILIATION_REASON
        )
      # Email address allowed but not required such as an alumnus
      elsif EmailAddressOptions.not_required?(change.affiliations)
        # Never logged in
        if google_account.never_logged_in?
          schedule_actions!(
            Workers::Deprovisioning.schedule_for(account_email, :never_active, true),
            DeprovisionSchedule::NEVER_ACTIVE_REASON
          )
          :update

        # Logged in over a year ago
        elsif google_account.inactive?
          schedule_actions!(
            Workers::Deprovisioning.schedule_for(account_email, :inactive, true),
            DeprovisionSchedule::INACTIVE_REASON
          )
          :update

        # Logged in within the last year
        else
          :nothing
        end
      else
        :nothing
      end
    end

    # Should this change trigger a deprovisoning
    # @return [Boolean]
    def ignore?
      return true unless change.university_email_exists?
      return true unless change.affiliations_changed?

      email = PersonEmail.where(uuid: change.person_uuid, address: change.university_email).first
      return true if email.try(:excluded?)
      return true if email.try(:being_deprovisioned?)

      return false if !EmailAddressOptions.allowed?(change.affiliations)
      EmailAddressOptions.not_required?(change.affiliations) && google_account.active?
    end

    private

    # The PersonEmail associated with the `change`
    # @return [PersonEmail]
    def account_email
      @account_email ||= PersonEmail.find_by(uuid: change.person_uuid, address: change.university_email)
    end

    # Simple wrapper for the Workers::ScheduleActions worker
    # @return [String] Sidekiq worked job ID
    def schedule_actions!(actions_and_durations, reason)
      # TODO: Uncomment this (among other things) when we want to reactivate automatic email deprovisioning
      # Workers::ScheduleActions.perform_async(account_email.id.to_s, actions_and_durations, reason)
      return 'skipping this for now..'
    end
  end
end
