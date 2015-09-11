module Workers
  # Creates an email in all the university_emails collection, Trogdir and the
  #   legacy email table
  class CreateEmail
    include Sidekiq::Worker

    # Creates an email in all the university_emails collection, Trogdir and the
    #   legacy email table
    # @return [nil]
    def perform(uuid, address, primary = true)
      biola_id = TrogdirPerson.new(uuid).biola_id

      email = UniversityEmail.create! uuid: uuid, address: address, primary: primary if !Settings.dry_run?
      Log.info %{Create UniversityEmail for uuid: "#{uuid}" with address: "#{address}" }
      Workers::Trogdir::CreateEmail.perform_async uuid, address
      Workers::LegacyEmailTable::Insert.perform_async(biola_id, address)
      # TODO: we should probably create the email in Google here too

      email
    end
  end
end
