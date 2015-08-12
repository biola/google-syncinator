module ServiceObjects
  # Gets a unique email address and assigns it to a person in Trogdir
  class AssignEmailAddress < Base
    # The email type to use in Trogdir
    EMAIL_TYPE = :university
    # Whether or not the email we assign should be the primary
    MAKE_EMAIL_PRIMARY = true

    # Asks for a new unique email address and stores it in the university_emails
    #   collection, Trogdir and the legacy email table
    # @return [:create]
    def call
      email_options = EmailAddressOptions.new(change.affiliations, change.preferred_name, change.first_name, change.middle_name, change.last_name).to_a
      return nil if email_options.none?

      unique_email = UniqueEmailAddress.new(email_options).best
      full_unique_email = GoogleAccount.full_email(unique_email)

      UniversityEmail.create! uuid: change.person_uuid, address: full_unique_email if !Settings.dry_run?
      Log.info %{Create UniversityEmail for uuid: "#{change.person_uuid}" with address: "#{full_unique_email}" }
      Workers::CreateTrogdirEmail.perform_async change.person_uuid, full_unique_email
      Workers::InsertIntoLegacyEmailTable.perform_async(change.biola_id, full_unique_email)

      :create
    end

    # Should an email address be assigned to this change
    # @note If the person has a reprovisionable email, return false because
    #   ReprovisionGoogleAccount will handle it instead
    # @return [Boolean]
    def ignore?
      return true unless change.affiliation_added?
      return true if UniversityEmail.active? change.person_uuid
      !(EmailAddressOptions.required?(change.affiliations) && UniversityEmail.find_reprovisionable(change.person_uuid).blank?)
    end
  end
end
