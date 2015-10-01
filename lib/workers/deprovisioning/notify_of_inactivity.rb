module Workers
  module Deprovisioning
    # Sends an email to the associated account email notifying the owner that
    #   the account is scheduled to be closed unless it becomes active
    class NotifyOfInactivity < Base
      include Sidekiq::Worker

      # Sends an email to the associated account email notifying the owner
      #   that the account is scheduled to be closed unless it becomes active
      # @param deprovision_schedule_id [Integer] ID of the notify_of_inactivity
      #   DeprovisionSchedule to be completed
      # @return [nil]
      def perform(deprovision_schedule_id)
        schedule = find_schedule(deprovision_schedule_id)
        email = schedule.account_email

        if deprovisioning_no_longer_warranted?(schedule)
          email.cancel_deprovisioning!
          return nil
        end

        unless schedule.canceled?
          if GoogleAccount.new(email.address).active?
            email.cancel_deprovisioning!
          else
            Emails::NotifyOfInactivity.new(schedule).send!
            schedule.update completed_at: DateTime.now if !Settings.dry_run?
            Log.info "Marked notify_of_inactivity schedule for #{email} complete"
          end
        end

        nil
      end
    end
  end
end
