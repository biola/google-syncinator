module Workers
  module Deprovisioning
    # Activates an email in the university_emails collection, Trogdir and
    #   the legacy email table
    class Activate < Base
      include Sidekiq::Worker

      # Runs the worker activating the email in university_emails, Trogdir and
      #   the legacy email table
      # @note We don't need to unsuspend or create the Google account here.
      #   That will happen after the Trogdir email is created.
      # @param deprovision_schedule_id [Integer] ID of the activate
      #   DeprovisionSchedule to be completed
      # @return [nil]
      def perform(deprovision_schedule_id)
        schedule = find_schedule(deprovision_schedule_id)
        email = schedule.university_email

        unless email.active?
          biola_id = TrogdirPerson.new(email.uuid).biola_id

          schedule.update completed_at: Time.now unless Settings.dry_run?
          Log.info "Create activation schedule for #{email}"
          Workers::CreateTrogdirEmail.perform_async email.uuid, email.address
          Workers::UnexpireLegacyEmailTable.perform_async(biola_id, email.address)
        end

        nil
      end
    end
  end
end