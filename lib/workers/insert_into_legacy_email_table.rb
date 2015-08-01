module Workers
  class InsertIntoLegacyEmailTable
    include Sidekiq::Worker

    def perform(biola_id, email)
      DB[:email].insert(idnumber: biola_id, email: email) if !Settings.dry_run?
      Log.info "Insert record into legacy email table: idnumber: #{biola_id}, email: #{email}"
    end
  end
end
