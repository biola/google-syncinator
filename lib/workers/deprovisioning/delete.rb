module Workers
  module Deprovisioning
    class Delete
      include Sidekiq::Worker

      def perform(university_email_id)
        email = UniversityEmail.find(university_email_id)
        schedule = email.deprovision_schedules.find_by(action: :delete, job_id: jid)

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
