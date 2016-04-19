module ServiceObjects
  # Update Biola ID in the legacy email table when it changes in Trogdir
  class UpdateBiolaID < Base
    # Update the Biola ID in the legacy email table
    def call
      Workers::LegacyEmailTable::UpdateID.perform_async(change.old_id, change.new_id)

      :update
    end

    # Was the Biola ID changed in Trogdir
    def ignore?
      !change.biola_id_updated?
    end
  end
end
