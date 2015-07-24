module Workers
  class CheckInactive
    include Sidekiq::Worker
    include Sidetiq::Schedulable

    recurrence { weekly }

    def perform
      GoogleAccount.inactive.each do |email_address|
        email = UniversityEmail.current(email_address)

        unless email.being_deprovisioned?
          # TODO: all times should be set in config
          Workers::ScheduleActions.perform_async email.uuid, 5.days.to_i, :notify_of_inactivity, 27.days.to_i, :notify_of_inactivity, 3.days.to_i, :suspend, 6.months.to_i, :delete
        end
      end
    end
  end
end
