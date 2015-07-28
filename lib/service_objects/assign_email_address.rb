module ServiceObjects
  class AssignEmailAddress < Base
    EMAIL_TYPE = :university
    MAKE_EMAIL_PRIMARY = true

    def call
      email_options = EmailAddressOptions.new(change.affiliations, change.preferred_name, change.first_name, change.middle_name, change.last_name).to_a
      return nil if email_options.none?

      unique_email = UniqueEmailAddress.new(email_options).best
      full_unique_email = GoogleAccount.full_email(unique_email)

      UniversityEmail.create! uuid: change.person_uuid, address: full_unique_email if !Settings.dry_run?
      Log.info %{Create UniversityEmail for uuid: "#{change.person_uuid}" with address }
      Workers::CreateTrogdirEmail.perform_async change.person_uuid, full_unique_email
      Workers::InsertIntoLegacyEmailTable.perform_async(change.biola_id, full_unique_email)

      :create
    end

    def ignore?
      return true unless change.affiliation_added?
      return true if UniversityEmail.active? change.person_uuid
      # If the person has a reprovisionable email, let ReprovisionGoogleAccount handle it
      !(EmailAddressOptions.required?(change.affiliations) && UniversityEmail.find_reprovisionable(change.person_uuid).blank?)
    end
  end
end
