module Workers
  module Deprovisioning
    # Suspends an email in the university_emails collection, Trogdir and
    #   the legacy email table
    class Suspend < Base
      include Sidekiq::Worker

      # Runs the worker suspending the email in university_emails, Trogdir and
      #   the legacy email table
      # @param deprovision_schedule_id [Integer] ID of the suspend
      #   DeprovisionSchedule to be completed
      # @return [nil]
      def perform(deprovision_schedule_id)
        schedule = find_schedule(deprovision_schedule_id)
        email = schedule.university_email

        unless schedule.canceled?
          biola_id = TrogdirPerson.new(email.uuid).biola_id

          GoogleAccount.new(email.address).suspend!
          DeleteTrogdirEmail.perform_async(email.uuid, email.address)
          ExpireLegacyEmailTable.perform_async(biola_id, email.address)
          schedule.update completed_at: DateTime.now if !Settings.dry_run?
          Log.info "Marked suspend schedule for #{email} complete"
        end
      end
    end
  end
end
