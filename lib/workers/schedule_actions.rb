module Workers
  # Schedules actions by creating deprovision schedules on university emails
  #   and scheduling sidekiq workers to be run in the future
  class ScheduleActions
    include Sidekiq::Worker

    # Schedules actions by creating deprovision schedules on university emails
    #   and scheduling sidekiq workers to be run in the future
    # @note This keeps track of the duration between each step so you can just pass in the time from the last step
    #   instead of always having to figure out the time from now
    # @example
    #   schedule_actions! 5.days.to_i, :notify_of_closure, 1.week.to_i, :suspend, 6.months.to_i, :delete
    # @param university_email_id [String] ID of the UniversityEmail that should be acted upon
    # @param actions_and_durations [Array<Integer, String>] the actions that
    #   should be taken and the amount of time in seconds between each action
    # @return [nil]
    def perform(university_email_id, *actions_and_durations)
      # Because of Sidekiq's JSON serialization actions come across as strings
      # so convert them to symbols to match how they are in the rest of the code
      actions_and_durations.map! { |ad| ad.is_a?(String) ? ad.to_sym : ad }
      email = UniversityEmail.find(university_email_id)
      seconds = 0

      unless actions_and_durations.all? { |ad| ad.is_a?(Integer) || ad.is_a?(Symbol) }
        raise ArgumentError, 'actions_and_durations must be either integers or strings'
      end

      if actions_and_durations.none? { |ad| ad.is_a?(Symbol) }
        raise ArgumentError, 'actions_and_durations must contain at least one action'
      end

      if (actions_and_durations.select { |a| a.is_a?(Symbol) } - DeprovisionSchedule::ACTIONS).any?
        raise ArgumentError, "action symbols must be one of #{DeprovisionSchedule::ACTIONS.join()}"
      end

      email.cancel_deprovisioning!

      actions_and_durations.each do |duration_or_action|
        duration = action = duration_or_action # variable aliasing for readability

        if duration_or_action.is_a? Numeric
          seconds += duration
        else
          scheduled_for = Time.now + seconds

          schedule = email.deprovision_schedules.build(action: action, scheduled_for: scheduled_for)
          schedule.save_and_schedule!

          Log.info "Scheduled an action of #{action} on #{scheduled_for} for #{email}"
        end
      end

      nil
    end
  end
end
