module Workers
  # Scheduled Sidekiq worker that check for Google accounts that are not
  #   required and have never been active and schedule them for deprovisioning
  class CheckNeverActive
    include Sidekiq::Worker
    include Sidetiq::Schedulable

    recurrence { weekly }

    # Find never active Google accounts and schedule them to be deprovisioned
    # @return [nil]
    def perform
      GoogleAccount.never_active.each do |email_address|
        email = UniversityEmail.current(email_address)

        unless email.being_deprovisioned? || email.protected?
          person = TrogdirPerson.new(email.uuid)

          if EmailAddressOptions.not_required?(person.affiliations)
            if GoogleAccount.new(email_address).never_active?
              Workers::ScheduleActions.perform_async email.uuid, *Settings.deprovisioning.schedules.allowed.never_active
            end
          end
        end
      end

      nil
    end
  end
end