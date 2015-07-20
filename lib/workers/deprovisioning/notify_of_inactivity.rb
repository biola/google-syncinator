module Workers
  module Deprovisioning
    class NotifyOfInactivity
      include Sidekiq::Worker

      def perform(university_email_id)
        email = UniversityEmail.find(university_email_id)
        schedule = email.deprovision_schedules.find_by(action: :notify_of_inactivity, job_id: jid)

        unless schedule.canceled?
          # TODO: grab duration from config
          if GoogleAccount.new(email.address).last_login > 1.year.ago
            email.cancel_deprovisioning!
          else
            Emails::NotifyOfInactivity.new(schedule).send!
            schedule.update completed_at: DateTime.now
          end
        end
      end
    end
  end
end
