module Workers
  module LegacyEmailTable
    # Creates an email record in the legacy WS email table
    class Insert
      include Sidekiq::Worker

      # @param biola_id [Integer] Biola ID number of the user who will own the email
      # @param email [String] Email address to create
      # @param primary [Boolean] Whether this is a primary email or an alias
      # @return [nil]
      def perform(biola_id, email, primary = true)
        DB[:email].insert(idnumber: biola_id, email: email, primary: primary) if Enabled.write?
        Log.info "Insert record into legacy email table: idnumber: #{biola_id}, email: #{email}"

        nil
      end
    end
  end
end
