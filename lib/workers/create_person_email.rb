module Workers
  # Creates an email in all the university_emails collection, Trogdir and the
  #   legacy email table
  class CreatePersonEmail
    include Sidekiq::Worker

    # Creates an email in all the university_emails collection, Trogdir and the
    #   legacy email table
    # @param uuid [String] the UUID of the Trogdir person
    # @param address [String] the email address to create
    # @return [nil]
    def perform(uuid, address)
      person = TrogdirPerson.new(uuid)
      org_unit_path = OrganizationalUnit.path_for(person)

      email = PersonEmail.create! uuid: uuid, address: address if Enabled.write?
      Log.info %{Create PersonEmail for uuid: "#{uuid}" with address: "#{address}" }
      Workers::Trogdir::CreateEmail.perform_async uuid, address
      Workers::LegacyEmailTable::Insert.perform_async(person.biola_id, address)
      GoogleAccount.new(address).create!(
        first_name: person.first_or_preferred_name,
        last_name: person.last_name,
        department: person.department,
        title: person.title,
        privacy: person.privacy,
        org_unit_path: org_unit_path
      )

      email
    end
  end
end
