module ServiceObjects
  class UpdateLegacyEmailTable < Base
    DB = Sequel.connect(Settings.ws.db.to_hash)

    def call(email)
      DB[:email].insert(idnumber: change.biola_id, email: email)
    end

    def ignore?
      !(change.affiliation_added? && !change.university_email_exists?)
    end
  end
end
