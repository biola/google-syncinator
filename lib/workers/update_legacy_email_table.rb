module Workers
  class UpdateLegacyEmailTable
    include Sidekiq::Worker

    def perform(biola_id, old_email, new_email)
      db = Sequel.connect(Settings.ws.db.to_hash)

      db[:email].where(idnumber: biola_id, email: old_email).update(primary: 0)
      if db[:email].where(idnumber: biola_id, email: new_email).count > 0
        db[:email].where(idnumber: biola_id, email: new_email).update(primary: 1, expiration_date: "0000-00-00 00:00:00")
      else
        db[:email].insert(idnumber: biola_id, email: new_email)
      end
    end
  end
end
