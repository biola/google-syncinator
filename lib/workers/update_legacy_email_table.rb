module Workers
  class UpdateLegacyEmailTable
    include Sidekiq::Worker

    def perform(biola_id, old_email, new_email)
      db = Sequel.connect(Settings.ws.db.to_hash)

      db[:email].where(idnumber: biola_id, email: old_email).update(primary: 0) if !Settings.dry_run?
      Log.info "Set primary = 0 in legacy email table where biola_id = #{biola_id} and email = #{old_email}"
      if db[:email].where(idnumber: biola_id, email: new_email).count > 0
        db[:email].where(idnumber: biola_id, email: new_email).update(primary: 1, expiration_date: "0000-00-00 00:00:00") if !Settings.dry_run?
        Log.info "Set primary = 1 and expiration_date to blank in legacy email table where biola_id = #{biola_id} and email = #{new_email}"
      else
        db[:email].insert(idnumber: biola_id, email: new_email) if !Settings.dry_run?
        Log.info "Insert into legacy email table biola_id: #{biola_id}, email: #{new_email}"
      end
    end
  end
end
