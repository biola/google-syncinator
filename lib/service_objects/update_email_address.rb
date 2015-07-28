module ServiceObjects
  class UpdateEmailAddress < Base
    def call
      # The ID hash does not come through with the hash of the person ids
      # So we have to make a work around for it.
      biola_id = TrogdirPerson.new(change.person_uuid).biola_id
      Workers::UpdateLegacyEmailTable.perform_async(biola_id, change.old_university_email, change.new_university_email)
      # TODO: update UniversityEmail too
      :update
    end

    def ignore?
      !change.university_email_updated?
    end
  end
end
