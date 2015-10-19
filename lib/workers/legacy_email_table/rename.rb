module Workers
  module LegacyEmailTable
    # Creates an email record in the legacy WS email table
    class Rename
      include Sidekiq::Worker

      # @param biola_id [Integer] Biola ID number of the user
      # @param old_address [Integer] Email address that should be changed
      # @param new_address [Integer] The new mail address
      # @return [nil]
      def perform(biola_id, old_address, new_address)
        record = DB[:email].where(idnumber: biola_id, email: old_address).first

        if Enabled.write?
          DB[:email].where(id: record[:id]).update primary: 0
          Insert.perform_async biola_id, new_address, true
        end

        Log.info "Update address in legacy email table: old address: #{old_address}, new address: #{new_address}"

        nil
      end
    end
  end
end
