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
          GoogleAccount.new(email.address).unsuspend!

          if email.sync_to_trogdir?
            Workers::Trogdir::CreateEmail.perform_async email.uuid, email.address
          end

          if email.sync_to_legacy_email_table?
            biola_id = TrogdirPerson.new(email.uuid).biola_id
            Workers::LegacyEmailTable::Unexpire.perform_async(biola_id, email.address)
          end

          schedule.update completed_at: Time.now if Enabled.write?
          Log.info "Create activation schedule for #{email}"
        end

        nil
      end
    end
  end
end
