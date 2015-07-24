module Workers
  class ScheduleActions
    include Sidekiq::Worker

    # This keeps track of the duration between each step so you can just pass in the time from the last step
    # instead of always having to figure out the time from now
    # Example: schedule_actions! 5.days.to_i, :notify_of_closure, 1.week.to_i, :suspend, 6.months.to_i, :delete
    def perform(uuid, *actions_and_durations)
      unless actions_and_durations.all? { |ad| ad.is_a?(Integer) || ad.is_a?(Symbol) }
        raise ArgumentError, 'actions_and_durations must be either integers or symbols'
      end

      if actions_and_durations.none? { |ad| ad.is_a?(Symbol) }
        raise ArgumentError, 'actions_and_durations must contain at least one action'
      end

      if (actions_and_durations.select { |a| a.is_a?(Symbol) } - DeprovisionSchedule::ACTIONS).any?
        raise ArgumentError, "action symbols must be one of #{DeprovisionSchedule::ACTIONS.join()}"
      end

      seconds = 0
      actions_and_durations.each do |duration_or_action|
        duration = action = duration_or_action # variable aliasing for readability

        if duration_or_action.is_a? Numeric
          seconds += duration
        else
          university_emails = if action == :activate
            [UniversityEmail.find_reprovisionable(uuid)]
          else
            UniversityEmail.where(uuid: uuid, state: :active)
          end

          university_emails.each do |univ_email|
            job_id = Workers::Deprovisioning.const_get(action.to_s.classify).perform_in(seconds, univ_email.id)
            univ_email.deprovision_schedules << DeprovisionSchedule.new(action: action, scheduled_for: (Time.now + seconds), job_id: job_id)
          end
        end
      end
    end
  end
end
