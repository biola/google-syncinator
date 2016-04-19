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

        if deprovisioning_no_longer_warranted?(schedule)
          email.cancel_deprovisioning!
          return nil
        end

        unless schedule.canceled?
          GoogleAccount.new(email.address).suspend!

          if email.sync_to_trogdir?
            Trogdir::DeleteEmail.perform_async(email.uuid, email.address)
          end

          if email.sync_to_legacy_email_table?
            biola_id = TrogdirPerson.new(email.uuid).biola_id
            LegacyEmailTable::Expire.perform_async(biola_id, email.address)
          end

          schedule.update completed_at: DateTime.now if Enabled.write?
          Log.info "Marked suspend schedule for #{email} complete"
        end
      end
    end
  end
end
