module ServiceObjects
  class UpdateBiolaID < Base
    def call
      Workers::LegacyEmailTable::UpdateID.perform_async(change.old_id, change.new_id)

      :update
    end

    def ignore?
      !change.biola_id_updated?
    end
  end
end
