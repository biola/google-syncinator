module Workers
  module Deprovisioning
    # Sends an email to the associated account email notifying the owner that
    #   the account is scheduled to be closed
    class NotifyOfClosure < Base
      include Sidekiq::Worker

      # Sends an email to the associated account email notifying the owner
      #   that the account is scheduled to be closed
      # @param deprovision_schedule_id [Integer] ID of the notify_of_closure
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
          Emails::NotifyOfClosure.new(schedule).send!
          schedule.update completed_at: DateTime.now if Enabled.write?
          Log.info "Marked notify_of_closure schedule for #{email} complete"
        end

        nil
      end
    end
  end
end
