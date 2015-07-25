module Workers
  class CheckNeverActive
    include Sidekiq::Worker
    include Sidetiq::Schedulable

    recurrence { weekly }

    def perform
      GoogleAccount.never_active.each do |email_address|
        email = UniversityEmail.current(email_address)

        unless email.being_deprovisioned?
          person = TrogdirPerson.new(email.uuid)

          if EmailAddressOptions.not_required?(person.affiliations)
            # TODO: ensure we're past the 1 month buffer
            # TODO: all times should be set in config
            Workers::ScheduleActions.perform_async email.uuid, 5.days.to_i, :suspend, 6.months.to_i, :delete
          end
        end
      end
    end
  end
end
