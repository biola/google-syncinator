module ServiceObjects
  class UpdateEmailAddress < Base
    def call
      # The ID hash does not come through with the hash of the person ids
      # So we have to make a work around for it.
      if change.biola_id_updated?
        UpdateLegacyEmailTable.new(change).insert_and_update_id(change.old_biola_id, change.new_biola_id)
      else
        biola_id = TrogdirPerson.new(change.person_uuid).biola_id
        UpdateLegacyEmailTable.new(change).insert_and_update_address(biola_id, change.old_university_email, change.new_university_email)
      end
      :update
    end

    def ignore?
      !(change.university_email_updated? || change.biola_id_updated?)
    end
  end
end
