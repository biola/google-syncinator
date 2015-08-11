module Workers
  # Creates an email record in the legacy WS email table
  class InsertIntoLegacyEmailTable
    include Sidekiq::Worker

    # @param biola_id [Integer] Biola ID number of the user who will own the email
    # @param email [String] Email address to create
    # @return [nil]
    def perform(biola_id, email)
      DB[:email].insert(idnumber: biola_id, email: email) if !Settings.dry_run?
      Log.info "Insert record into legacy email table: idnumber: #{biola_id}, email: #{email}"

      nil
    end
  end
end
