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
        email = schedule.account_email

        if deprovisioning_no_longer_warranted?(schedule)
          email.cancel_deprovisioning!
          return nil
        end

        unless schedule.canceled?
          GoogleAccount.new(email.address).delete!

          if email.class.sync_to_trogdir?
            Trogdir::DeleteEmail.perform_async(email.uuid, email.address)
          end

          if email.class.sync_to_legacy_email_table?
            biola_id = TrogdirPerson.new(email.uuid).biola_id
            LegacyEmailTable::Expire.perform_async(biola_id, email.address)
          end

          schedule.update completed_at: DateTime.now if Enabled.write?
          Log.info "Marked delete schedule for #{email} complete"
        end

        nil
      end
    end
  end
end
