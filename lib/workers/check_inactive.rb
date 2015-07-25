module Workers
  class CheckInactive
    include Sidekiq::Worker
    include Sidetiq::Schedulable

    recurrence { weekly }

    def perform
      GoogleAccount.inactive.each do |email_address|
        email = UniversityEmail.current(email_address)

        unless email.being_deprovisioned?
          person = TrogdirPerson.new(email.uuid)

          if EmailAddressOptions.not_required?(person.affiliations)
            # TODO: double check that they're inactive
            # TODO: ensure we're past the 1 month buffer
            Workers::ScheduleActions.perform_async email.uuid, *Settings.deprovisioning.schedules.allowed.inactive
          end
        end
      end
    end
  end
end
