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
      email_addresses = GoogleAccount.never_active

      email_addresses.each do |email_address|
        email = AccountEmail.current(email_address)

        unless email.being_deprovisioned? || email.protected?
          person = TrogdirPerson.new(email.uuid)

          if EmailAddressOptions.not_required?(person.affiliations)
            if GoogleAccount.new(email_address).never_active?
              Workers::ScheduleActions.perform_async email.id.to_s, Settings.deprovisioning.schedules.allowed.never_active, DeprovisionSchedule::NEVER_ACTIVE_REASON
            end
          end
        end
      end

      # Emails that are pending deprovisioning because they were never active
      pending_emails = AccountEmail.where(:deprovision_schedules.elem_match => {reason: DeprovisionSchedule::NEVER_ACTIVE_REASON, completed_at: nil, canceled: nil})

      pending_emails.each do |email|
        # Cancel deprovisioning if they have become active
        email.cancel_deprovisioning! if email_addresses.exclude? email.address
      end

      nil
    end
  end
end
