module Workers
  module Deprovisioning
    class Activate
      include Sidekiq::Worker

      def perform(university_email_id)
        email = UniversityEmail.find(university_email_id)

        unless email.active?
          biola_id = TrogdirPerson.new(email.uuid).biola_id

          # Activation can always happen right away, so no need to schedule it for the future like the others
          email.deprovision_schedules << DeprovisionSchedule.new(action: :activate, scheduled_for: DateTime.now, completed_at: DateTime.now)
          Workers::CreateTrogdirEmail.perform_async email.uuid, email.address
          Workers::UnexpireLegacyEmailTable.perform_async(biola_id, email.address)
          # We don't need to unsuspend or create the Google account here. That will happen after the Trogdir email is created.
        end
      end
    end
  end
end
