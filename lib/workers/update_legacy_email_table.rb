module Workers
  # Update an email address in the legacy WS email table
  class UpdateLegacyEmailTable
    include Sidekiq::Worker

    # Mark the old email address as not primary and creates a new primary email
    # @param biola_id [Integer] Biola ID number of the user who owns the email
    # @param old_email [String] Existing email address
    # @param new_email [String] New primary email address to create
    # @return [nil]
    def perform(biola_id, old_email, new_email)
      DB[:email].where(idnumber: biola_id, email: old_email).update(primary: 0) if !Settings.dry_run?
      Log.info "Set primary = 0 in legacy email table where biola_id = #{biola_id} and email = #{old_email}"
      if DB[:email].where(idnumber: biola_id, email: new_email).count > 0
        DB[:email].where(idnumber: biola_id, email: new_email).update(primary: 1, expiration_date: "0000-00-00 00:00:00") if !Settings.dry_run?
        Log.info "Set primary = 1 and expiration_date to blank in legacy email table where biola_id = #{biola_id} and email = #{new_email}"
      else
        DB[:email].insert(idnumber: biola_id, email: new_email, primary: 1) if !Settings.dry_run?
        Log.info "Insert into legacy email table biola_id: #{biola_id}, email: #{new_email}"
      end

      nil
    end
  end
end
