module Workers
  class InsertIntoLegacyEmailTable
    include Sidekiq::Worker

    def perform(biola_id, email)
      db = Sequel.connect(Settings.ws.db.to_hash)
      db[:email].insert(idnumber: biola_id, email: email)
    end
  end
end
