module Workers
  module LegacyEmailTable
    # Creates an email record in the legacy WS email table
    class UpdateID
      include Sidekiq::Worker

      # @param old_biola_id [Integer] Biola ID number of the user before the change
      # @param new_biola_id [Integer] Biola ID number of the user after the change
      # @return [nil]
      def perform(old_biola_id, new_biola_id)
        records = DB[:email].where(idnumber: old_biola_id)

        if records.count > 0
          records.update(idnumber: new_biola_id)
        end

        Log.info "Update idnumber in legacy email table: old idnumber: #{old_biola_id}, new idnumber: #{new_biola_id}"

        nil
      end
    end
  end
end
