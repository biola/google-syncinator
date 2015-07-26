module Workers
  module Deprovisioning
    class NotifyOfClosure
      include Sidekiq::Worker

      def perform(university_email_id)
        email = UniversityEmail.find(university_email_id)
        schedule = email.deprovision_schedules.find_by(action: :notify_of_closure, job_id: jid)

        unless schedule.canceled?
          # Only send a notice to the primary email to avoid duplicate emails
          Emails::NotifyOfClosure.new(schedule).send! if email.primary?
          schedule.update completed_at: DateTime.now
        end
      end
    end
  end
end
