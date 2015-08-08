module Workers
  module Deprovisioning
    class NotifyOfClosure < Base
      include Sidekiq::Worker

      def perform(deprovision_schedule_id)
        schedule = find_schedule(deprovision_schedule_id)
        email = schedule.university_email

        unless schedule.canceled?
          # Only send a notice to the primary email to avoid duplicate emails
          Emails::NotifyOfClosure.new(schedule).send! if email.primary?
          schedule.update completed_at: DateTime.now if !Settings.dry_run?
          Log.info "Marked notify_of_closure schedule for #{email} complete"
        end
      end
    end
  end
end
