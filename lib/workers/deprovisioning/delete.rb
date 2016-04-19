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

        if deprovisioning_no_longer_warranted?(schedule)
          email.cancel_deprovisioning!
          return nil
        end

        unless schedule.canceled?
          if email.is_a? AliasEmail
            GoogleAccount.new(email.account_email.address).delete_alias! email.address
          else
            GoogleAccount.new(email.address).delete!
          end

          if email.sync_to_trogdir?
            Trogdir::DeleteEmail.perform_async(email.uuid, email.address)
          end

          if email.sync_to_legacy_email_table?
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
