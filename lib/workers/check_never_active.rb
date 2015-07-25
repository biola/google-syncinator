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
            if GoogleAccount.new(email_address).never_active?
              # TODO: ensure we're past the 1 month buffer
              Workers::ScheduleActions.perform_async email.uuid, *Settings.deprovisioning.schedules.allowed.never_active
            end
          end
        end
      end
    end
  end
end
