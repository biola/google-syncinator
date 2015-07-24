module ServiceObjects
  class DeprovisionGoogleAccount < Base
    def call
      # TODO: check for 1 month buffer
      # TODO: all times should be set in config

      # Not allowed to have an email?
      if !EmailAddressOptions.allowed?(change.affiliations)

        # Never logged in
        if google_account.never_logged_in?
          schedule_actions! 5.days.to_i, :delete
          :schedule_deprovision

        # Has logged in
        else
          schedule_actions! 5.days.to_i, :notify_of_closure, 1.week.to_i, :suspend, 6.months.to_i, :delete
          :schedule_deprovision
        end

      # Email address allowed but not required such as an alumnus
      elsif EmailAddressOptions.not_required?(change.affiliations)

        # Never logged in
        if google_account.never_logged_in?
          schedule_actions! 5.days.to_i, :suspend, 6.months.to_i, :delete
          :schedule_deprovision

        # Logged in over a year ago
        elsif google_account.last_login < 1.year.ago
          schedule_actions! 5.days.to_i, :notify_of_inactivity, 27.days.to_i, :notify_of_inactivity, 3.days.to_i, :suspend, 6.months.to_i, :delete
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
      # TODO: check for exclusions
      EmailAddressOptions.allowed?(change.affiliations)
    end

    private

    def schedule_actions!(*actions_and_durations)
      Workers::ScheduleActions.perform_async(change.person_uuid, *actions_and_durations)
    end
  end
end
