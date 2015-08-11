module Workers
  # Expires an email record in the legacy WS email table
  class ExpireLegacyEmailTable
    # Exception for when a record is not found in the WS email table
    class RowNotFound < StandardError; end

    include Sidekiq::Worker

    # Expire an email record in the legacy WS email table
    # @param biola_id [Integer] Biola ID number of the user who owns the email
    # @param email_address [String] Email address to expire
    # @param expire_on [Time] Time when the email should be suspended
    # @param reusable_on [Time] Time when the email should be deleted
    # @return [nil]
    def perform(biola_id, email_address, expire_on = Time.now, reusable_on = nil)
      reusable_on ||= Time.now + Settings.deprovisioning.reusable_after

      row = DB[:email].where(idnumber: biola_id, email: email_address).first
      raise RowNotFound, %{Could not find legacy email table record for idnumber = "#{biola_id}" and email_address = "#{email_address}"} if row.nil?

      updates = {}
      updates[:expiration_date] = expire_on if row[:expiration_date].nil? || row[:expiration_date] > expire_on
      updates[:reusable_date] = reusable_on if row[:reusable_date].nil? || row[:reusable_date] > reusable_on

      DB[:email].where(idnumber: biola_id, email: email_address).update(updates) unless updates.empty? || Settings.dry_run?
      Log.info "Update legacy email table where biola_id = #{biola_id} and email = #{email_address} with #{updates.inspect}"

      nil
    end
  end
end
