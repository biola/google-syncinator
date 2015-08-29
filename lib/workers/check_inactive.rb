module Workers
  # Scheduled Sidekiq worker that check for Google accounts that are not
  #   required and have become inactive and schedule them for deprovisioning
  class CheckInactive
    include Sidekiq::Worker
    include Sidetiq::Schedulable

    recurrence { weekly }

    # Find inactive Google accounts and schedule them to be deprovisioned
    # @return [nil]
    def perform
      GoogleAccount.inactive.each do |email_address|
        email = UniversityEmail.current(email_address)

        unless email.being_deprovisioned? || email.protected?
          person = TrogdirPerson.new(email.uuid)

          if EmailAddressOptions.not_required?(person.affiliations)
            if GoogleAccount.new(email_address).inactive?
              Workers::ScheduleActions.perform_async email.uuid, *Settings.deprovisioning.schedules.allowed.inactive
            end
          end
        end
      end

      nil
    end
  end
end