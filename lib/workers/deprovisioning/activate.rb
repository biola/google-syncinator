module Workers
  module Deprovisioning
    class Activate < Base
      include Sidekiq::Worker

      def perform(deprovision_schedule_id)
        schedule = find_schedule(deprovision_schedule_id)
        email = schedule.university_email

        unless email.active?
          biola_id = TrogdirPerson.new(email.uuid).biola_id

          schedule.update completed_at: Time.now unless Settings.dry_run?
          Log.info "Create activation schedule for #{email}"
          Workers::CreateTrogdirEmail.perform_async email.uuid, email.address
          Workers::UnexpireLegacyEmailTable.perform_async(biola_id, email.address)
          # We don't need to unsuspend or create the Google account here. That will happen after the Trogdir email is created.
        end
      end
    end
  end
end
