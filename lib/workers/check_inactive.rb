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

        raise RuntimeError, "#{email_address} exists in Google Apps but not in the university_emails collection" if email.nil?

        unless email.being_deprovisioned? || email.protected?
          person = TrogdirPerson.new(email.uuid)

          if EmailAddressOptions.not_required?(person.affiliations)
            if GoogleAccount.new(email_address).inactive?
              Workers::ScheduleActions.perform_async email.id.to_s, *Settings.deprovisioning.schedules.allowed.inactive
            end
          end
        end
      end

      # TODO: cancel deprovisioning for emails there were inactive but now have been active

      nil
    end
  end
end
