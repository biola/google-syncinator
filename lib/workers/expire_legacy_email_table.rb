module Workers
  class ExpireLegacyEmailTable
    class RowNotFound < StandardError; end

    include Sidekiq::Worker

    def perform(biola_id, email_address, expire_on = Time.now, reusable_on = nil)
      reusable_on ||= Time.now + Settings.deprovisioning.reusable_after

      db = Sequel.connect(Settings.ws.db.to_hash)

      row = db[:email].where(idnumber: biola_id, email: email_address).first
      raise RowNotFound, %{Could not find legacy email table record for idnumber = "#{biola_id}" and email_address = "#{email_address}"} if row.nil?

      updates = {}
      updates[:expiration_date] = expire_on if row[:expiration_date].nil? || row[:expiration_date] > expire_on
      updates[:reusable_date] = reusable_on if row[:reusable_date].nil? || row[:reusable_date] > reusable_on

      db[:email].where(idnumber: biola_id, email: email_address).update(updates) unless updates.empty? || Settings.dry_run?
      Log.info "Update legacy email table where biola_id = #{biola_id} and email = #{email_address} with #{updates.inspect}"
    end
  end
end
