module ServiceObjects
  # Updates a changed email address in the legacy email table
  class UpdateEmailAddress < Base
    # Creates a new primary email with the new address and makes the previous one non-primary
    # @return [:update] the action taken
    def call
      # The ID hash does not come through with the hash of the person ids
      # So we have to make a work around for it.
      biola_id = TrogdirPerson.new(change.person_uuid).biola_id
      Workers::UpdateLegacyEmailTable.perform_async(biola_id, change.old_university_email, change.new_university_email)
      # TODO: update UniversityEmail and possibly GoogleAccount as well
      :update
    end

    # Should this change trigger a email address update
    # @return [Boolean]
    def ignore?
      !change.university_email_updated?
    end
  end
end
