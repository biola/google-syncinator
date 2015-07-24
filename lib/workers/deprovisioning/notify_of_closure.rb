module Workers
  module Deprovisioning
    class NotifyOfClosure
      include Sidekiq::Worker

      def perform(university_email_id)
        email = UniversityEmail.find(university_email_id)
        schedule = email.deprovision_schedules.find_by(action: :notify_of_closure, job_id: jid)

        unless schedule.canceled?
          #TODO: only notify on the primary email?
          Emails::NotifyOfClosure.new(schedule).send!
          schedule.update completed_at: DateTime.now
        end
      end
    end
  end
end
