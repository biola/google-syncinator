module Workers
  # Change the address of an email in all the university_emails collection,
  #   Trogdir and the legacy email table
  class RenamePersonEmail
    include Sidekiq::Worker

    # Change the address of an email in all the university_emails collection,
    #   Trogdir and the legacy email table
    # @param person_email_id [String] the ID of the PersonEmail
    # @param address [String] the new email address to use
    # @return [nil]
    # @note this will also cause the previous email address to become an alias
    def perform(person_email_id, new_address)
      email = PersonEmail.find(person_email_id)
      old_address = email.address.dup
      biola_id = TrogdirPerson.new(email.uuid).biola_id

      Log.info %{Rename PersonEmail address for uuid: "#{email.uuid}" from "#{old_address}" to "#{new_address}"}

      if Enabled.write?
        GoogleAccount.new(old_address).rename! new_address
        email.update! address: new_address
        AliasEmail.create! account_email: email, address: old_address
        Workers::Trogdir::RenameEmail.perform_async email.uuid, old_address, new_address
        Workers::LegacyEmailTable::Rename.perform_async(biola_id, old_address, new_address)
      end

      email
    end
  end
end
