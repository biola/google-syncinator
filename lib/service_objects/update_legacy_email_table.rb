module ServiceObjects
  class UpdateLegacyEmailTable < Base
    DB = Sequel.connect(Settings.ws.db.to_hash)

    def insert(email)
      DB[:email].insert(idnumber: change.biola_id, email: email)
    end

    def insert_and_update(biola_id, old_email, new_email)
      DB[:email].where(idnumber: biola_id, email: old_email).update(primary: 0)
      if DB[:email].where(idnumber: biola_id, email: new_email).count > 0
        DB[:email].where(idnumber: biola_id, email: new_email).update(primary: 1, expiration_date: "0000-00-00 00:00:00")
      else
        DB[:email].insert(idnumber: biola_id, email: new_email)
      end
    end

    def ignore?
      !(change.affiliation_added? && !change.university_email_exists?)
    end
  end
end
