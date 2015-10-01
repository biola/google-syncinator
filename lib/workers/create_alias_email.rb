module Workers
  # Creates an email in all the university_emails collection, Trogdir and the
  #   legacy email table
  class CreateAliasEmail
    include Sidekiq::Worker

    # Creates an email in all the university_emails collection, Trogdir and the
    #   legacy email table
    # @param account_email_id [String] ID of the account email record that should be aliased
    # @param address [String] the email address to create
    # @return [nil]
    def perform(account_email_id, address)
      account_email = AccountEmail.find(account_email_id)

      email = AliasEmail.create! account_email: account_email, address: address if !Settings.dry_run?
      Log.info %{Create AliasEmail for account_email: "#{account_email.address}" with address: "#{address}" }
      # For now we're keeping alias emails out of Trogdir. But if we wanted to turn that on this is where it should be done.
      # Workers::Trogdir::CreateEmail.perform_async account_email_id, address

      if account_email.respond_to? :uuid
        biola_id = TrogdirPerson.new(account_email.uuid).biola_id
        Workers::LegacyEmailTable::Insert.perform_async(biola_id, address, false)
      end

      GoogleAccount.new(account_email.address).create_alias! address

      email
    end
  end
end
