module Workers
  class UnexpireLegacyEmailTable
    include Sidekiq::Worker

    def perform(biola_id, email)
      if !Settings.dry_run?
        DB[:email].where(idnumber: biola_id, email: email).update(primary: 1, expiration_date: '0000-00-00 00:00:00', reusable_date: '0000-00-00 00:00:00')
      end

      Log.info "Unexpired legacy email table where biola_id = #{biola_id} and email = #{email}"
    end
  end
end
