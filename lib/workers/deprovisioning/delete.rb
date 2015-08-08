module Workers
  module Deprovisioning
    class Delete < Base
      include Sidekiq::Worker

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
      end
    end
  end
end
