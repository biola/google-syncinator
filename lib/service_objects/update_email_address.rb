module ServiceObjects
  # Updates a changed email address in the legacy email table
  class UpdateEmailAddress < Base
    # Creates a new primary email with the new address and makes the previous one non-primary
    # @return [:update] the action taken
    def call
      # The ID hash does not come through with the hash of the person ids
      # So we have to make a work around for it.
      biola_id = TrogdirPerson.new(change.person_uuid).biola_id
      Workers::LegacyEmailTable::Update.perform_async(biola_id, change.old_university_email, change.new_university_email)

      UniversityEmail.where(uuid: change.person_uuid, address: change.old_university_email).update(primary: false) if !Settings.dry_run?
      Log.info %{Update UniversityEmail for uuid: "#{change.person_uuid}" with address: #{change.old_university_email} to be not primary}
      UniversityEmail.create! uuid: change.person_uuid, address: change.new_university_email if !Settings.dry_run?
      Log.info %{Create UniversityEmail for uuid: "#{change.person_uuid}" with address: "#{change.new_university_email}" }

      GoogleAccount.new(change.old_university_email).rename! change.new_university_email if !Settings.dry_run?
      Log.info %{Rename GoogleAccount from "#{change.old_university_email} to "#{change.new_university_email}"}

      :update
    end

    # Should this change trigger a email address update
    # @return [Boolean]
    def ignore?
      !change.university_email_updated?
    end
  end
end
