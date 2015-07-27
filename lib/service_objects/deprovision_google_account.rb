module ServiceObjects
  class DeprovisionGoogleAccount < Base
    def call
      # If the email address was recently created and is in it's protection period,
      # then schedule deprovisioning for the end of the protected period
      if university_email.protected?
        # Add 5 minutes to be sure we're past the protection time
        Workers::DeprovisionGoogleAccount.perform_at(university_email.protected_until + 300, change.hash)
        return :nothing
      end

      # Not allowed to have an email?
      if !EmailAddressOptions.allowed?(change.affiliations)

        # Never logged in
        if google_account.never_logged_in?
          schedule_actions!(*Settings.deprovisioning.schedules.unallowed.never_active)
          :schedule_deprovision

        # Has logged in
        else
          schedule_actions!(*Settings.deprovisioning.schedules.unallowed.active)
          :schedule_deprovision
        end

      # Email address allowed but not required such as an alumnus
      elsif EmailAddressOptions.not_required?(change.affiliations)

        # Never logged in
        if google_account.never_logged_in?
          schedule_actions!(*Settings.deprovisioning.schedules.allowed.never_active)
          :schedule_deprovision

        # Logged in over a year ago
      elsif google_account.inactive?
          schedule_actions!(*Settings.deprovisioning.schedules.allowed.inactive)
          :schedule_deprovision

        # Logged in within the last year
        else
          :nothing
        end
      else
        :nothing
      end
    end

    def ignore?
      return true unless change.university_email_exists?
      return true unless change.affiliations_changed?
      return true if UniversityEmail.where(uuid: change.person_uuid, address: change.university_email).first.try(:excluded?)
      EmailAddressOptions.allowed?(change.affiliations)
    end

    private

    def university_email
      @university_email ||= UniversityEmail.find_by(uuid: change.person_uuid, address: change.university_email)
    end

    def schedule_actions!(*actions_and_durations)
      Workers::ScheduleActions.perform_async(change.person_uuid, *actions_and_durations)
    end
  end
end
