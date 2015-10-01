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
      email_addresses = GoogleAccount.inactive

      email_addresses.each do |email_address|
        email = AccountEmail.current(email_address)

        raise RuntimeError, "#{email_address} exists in Google Apps but not in the university_emails collection" if email.nil?

        unless email.being_deprovisioned? || email.protected?
          person = TrogdirPerson.new(email.uuid)

          if EmailAddressOptions.not_required?(person.affiliations)
            if GoogleAccount.new(email_address).inactive?
              Workers::ScheduleActions.perform_async email.id.to_s, Settings.deprovisioning.schedules.allowed.inactive, DeprovisionSchedule::INACTIVE_REASON
            end
          end
        end
      end

      # Emails that are pending deprovisioning because they were never active
      pending_emails = AccountEmail.where(:deprovision_schedules.elem_match => {reason: DeprovisionSchedule::INACTIVE_REASON, completed_at: nil, canceled: nil})

      pending_emails.each do |email|
        # Cancel deprovisioning if they have become active
        email.cancel_deprovisioning! if email_addresses.exclude? email.address
      end

      nil
    end
  end
end
