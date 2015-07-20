module ServiceObjects
  class DeprovisionGoogleAccount < Base
    def call
      # TODO: check for 1 month buffer
      # TODO: all times should be set in config

      # Not allowed to have an email?
      if !EmailAddressOptions.allowed?(change.affiliations)

        # Never logged in
        if google_account.never_logged_in?
          schedule_action! :delete, 5.days
          :schedule_deprovision

        # Has logged in
        else
          schedule_actions! 5.days => :notify_of_closure, 1.week => :suspend, 6.months => :delete
          :schedule_deprovision
        end

      # Email address allowed but not required such as an alumnus
      elsif EmailAddressOptions.not_required?(change.affiliations)

        # Never logged in
        if google_account.never_logged_in?
          schedule_actions! 5.days => :suspend, 6.months => :delete
          :schedule_deprovision

        # Logged in over a year ago
        elsif google_account.last_login < 1.year.ago
          schedule_actions! 5.days => :notify_of_inactivity, 27.days => :notify_of_inactivity, 3.days => :suspend, 6.months => :delete
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

    def university_emails
      @university_emails ||= UniversityEmail.where(uuid: change.person_uuid, state: :active)
    end

    # This keeps track of the duration between each step so you can just pass in the time from the last step
    # instead of always having to figure out the time from now
    # Example: schedule_actions! 5.days => :notify_of_closure, 1.week => :suspend, 6.months => :delete
    def schedule_actions!(actions_and_durations)
      raise ArgumentError, 'actions_and_durations must be a Hash' unless actions_and_durations.is_a? Hash

      time = 0.seconds
      actions_and_durations.each do |duration, action|
        time += duration
        schedule_action! action, duration
      end
    end

    def schedule_action!(action, duration)
      scheduled_for = duration.from_now.end_of_day

      university_emails.each do |univ_email|
        job_id = Workers::Deprovisioning.const_get(action.to_s.classify).perform_at(scheduled_for, univ_email.id)
        univ_email.deprovision_schedules << DeprovisionSchedule.new(action: action, scheduled_for: scheduled_for, job_id: job_id)
      end
    end
  end
end
