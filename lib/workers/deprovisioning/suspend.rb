module Workers
  module Deprovisioning
    class Suspend
      class TrogdirError < StandardError; end

      include Sidekiq::Worker

      def perform(university_email_id)
        email = UniversityEmail.find(university_email_id)
        schedule = email.deprovision_schedules.find_by(action: :suspend, job_id: jid)

        unless schedule.canceled?
          biola_id = TrogdirPerson.new(email.uuid).biola_id

          GoogleAccount.new(email.address).suspend!
          DeleteTrogdirEmail.perform_async(email.uuid, email.address)
          ExpireLegacyEmailTable.perform_async(biola_id, email.address)
          schedule.update completed_at: DateTime.now
        end
      end
    end
  end
end
