module Workers
  module Deprovisioning
    class NotifyOfInactivity
      include Sidekiq::Worker

      def perform(university_email_id)
        email = UniversityEmail.find(university_email_id)
        schedule = email.deprovision_schedules.find_by(action: :notify_of_inactivity, job_id: jid)

        unless schedule.canceled?
          if GoogleAccount.new(email.address).active?
            email.cancel_deprovisioning!
          else
            # Only send a notice to the primary email to avoid duplicate emails
            Emails::NotifyOfInactivity.new(schedule).send! if email.primary?
            schedule.update completed_at: DateTime.now
          end
        end
      end
    end
  end
end
