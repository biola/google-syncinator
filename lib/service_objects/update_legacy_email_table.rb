module ServiceObjects
  class UpdateLegacyEmailTable < Base
    DB = Sequel.connect(Settings.ws.db.to_hash)

    def insert(change, email)
      DB[:email].insert(idnumber: change.biola_id, email: email)
    end

    def insert_and_update(biola_id, old_email, new_email)
      DB[:email].where(idnumber: biola_id, email: old_email).update(primary: 0)
      DB[:email].insert(idnumber: biola_id, email: new_email)
    end

    def ignore?
      !(change.affiliation_added? && !change.university_email_exists?)
    end
  end
end
