module Workers
  module Deprovisioning
    # Deletes an email in the university_emails collection, Trogdir and
    #   the legacy email table
    class Delete < Base
      include Sidekiq::Worker

      # Runs the worker deleting the email in university_emails, Trogdir and
      #   the legacy email table
      # @param deprovision_schedule_id [Integer] ID of the delete
      #   DeprovisionSchedule to be completed
      # @return [nil]
      def perform(deprovision_schedule_id)
        schedule = find_schedule(deprovision_schedule_id)
        email = schedule.university_email

        unless schedule.canceled?
          biola_id = TrogdirPerson.new(email.uuid).biola_id

          GoogleAccount.new(email.address).delete!
          DeleteTrogdirEmail.perform_async(email.uuid, email.address)
          ExpireLegacyEmailTable.perform_async(biola_id, email.address)
          schedule.update completed_at: DateTime.now if !Settings.dry_run?
          Log.info "Marked delete schedule for #{email} complete"
        end

        nil
      end
    end
  end
end
