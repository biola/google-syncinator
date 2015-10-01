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

      email = PersonEmail.create! uuid: uuid, address: address if !Settings.dry_run?
      Log.info %{Create PersonEmail for uuid: "#{uuid}" with address: "#{address}" }
      Workers::Trogdir::CreateEmail.perform_async uuid, address
      Workers::LegacyEmailTable::Insert.perform_async(person.biola_id, address)
      GoogleAccount.new(address).create! person.first_or_preferred_name, person.last_name, person.department, person.title, person.privacy

      email
    end
  end
end
