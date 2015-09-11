module Workers
  module LegacyEmailTable
    # Activates an existing email record in the legacy WS email table
    class Unexpire
      include Sidekiq::Worker

      # Activate an existing email record in the legacy WS email table
      # @param biola_id [Integer] Biola ID number of the user who owns the email
      # @param email [String] Email address to unexpire
      # @return [nil]
      def perform(biola_id, email)
        if !Settings.dry_run?
          DB[:email].where(idnumber: biola_id, email: email).update(primary: 1, expiration_date: '0000-00-00 00:00:00', reusable_date: '0000-00-00 00:00:00')
        end

        Log.info "Unexpired legacy email table where biola_id = #{biola_id} and email = #{email}"

        nil
      end
    end
  end
end
