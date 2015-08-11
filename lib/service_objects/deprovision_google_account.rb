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
      if university_email.protected?
        # Add 5 minutes to be sure we're past the protection time
        # We won't schedule this during a dry run because even though it would be safe to do now, dry_run could be off when it actually runs
        Workers::DeprovisionGoogleAccount.perform_at(university_email.protected_until + 300, change.hash) if !Settings.dry_run?
        Log.info "Schedule deprovisioning of #{change.person_uuid}/#{change.university_email} for #{university_email.protected_until + 300}"
        return :nothing
      end

      # Not allowed to have an email?
      if !EmailAddressOptions.allowed?(change.affiliations)

        # Never logged in
        if google_account.never_logged_in?
          schedule_actions!(*Settings.deprovisioning.schedules.unallowed.never_active)
          :update

        # Has logged in
        else
          schedule_actions!(*Settings.deprovisioning.schedules.unallowed.active)
          :update
        end

      # Email address allowed but not required such as an alumnus
      elsif EmailAddressOptions.not_required?(change.affiliations)

        # Never logged in
        if google_account.never_logged_in?
          schedule_actions!(*Settings.deprovisioning.schedules.allowed.never_active)
          :update

        # Logged in over a year ago
        elsif google_account.inactive?
          schedule_actions!(*Settings.deprovisioning.schedules.allowed.inactive)
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
      return true if UniversityEmail.where(uuid: change.person_uuid, address: change.university_email).first.try(:excluded?)
      return false if !EmailAddressOptions.allowed?(change.affiliations)
      EmailAddressOptions.not_required?(change.affiliations) && google_account.active?
    end

    private

    # The UniversityEmail associated with the `change`
    # @return [UniversityEmail]
    def university_email
      @university_email ||= UniversityEmail.find_by(uuid: change.person_uuid, address: change.university_email)
    end

    # Simple wrapper for the Workers::ScheduleActions worker 
    # @return [String] Sidekiq worked job ID
    def schedule_actions!(*actions_and_durations)
      Workers::ScheduleActions.perform_async(change.person_uuid, *actions_and_durations)
    end
  end
end
