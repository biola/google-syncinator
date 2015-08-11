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
    # @param uuid [String] UUID of the person who's email should be acted upon
    # @param actions_and_durations [Array<Integer, String>] the actions that
    #   should be taken and the amount of time in seconds between each action
    # @return [nil]
    def perform(uuid, *actions_and_durations)
      # Because of Sidekiq's JSON serialization actions come across as strings
      # so convert them to symbols to match how they are in the rest of the code
      actions_and_durations.map! { |ad| ad.is_a?(String) ? ad.to_sym : ad }
      university_emails = nil
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

      actions_and_durations.each do |duration_or_action|
        duration = action = duration_or_action # variable aliasing for readability

        if duration_or_action.is_a? Numeric
          seconds += duration
        else
           if action == :activate
            university_emails = [UniversityEmail.find_reprovisionable(uuid)]
          else
            university_emails ||= UniversityEmail.where(uuid: uuid, state: :active, primary: true).to_a
          end

          university_emails.each do |univ_email|
            scheduled_for = Time.now + seconds

            # We won't schedule this during a dry run because even though it would be safe to do now, dry_run could be off when it actually runs
            if !Settings.dry_run?
              schedule = univ_email.deprovision_schedules.create(action: action, scheduled_for: scheduled_for)
              job_id = Workers::Deprovisioning.const_get(action.to_s.classify).perform_in(seconds, schedule.id.to_s)
              schedule.update job_id: job_id
            end

            Log.info "Scheduled an action of #{action} on #{scheduled_for} for #{univ_email}"
          end
        end
      end

      nil
    end
  end
end
