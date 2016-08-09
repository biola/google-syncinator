module Workers
  # Update the email account in all the university_emails collection,
  #   Trogdir and the legacy email table
  class UpdatePersonEmail
    include Sidekiq::Worker

    # Update the email account in all the university_emails collection,
    #   Trogdir and the legacy email table
    # @param first_name [String] The users first name
    # @param last_name [String] The users last name
    # @param address [String] The users email address
    # @param uuid [String] The users uuid from Trogdir
    # @param password [String] The users new password
    # @param vfe [Boolean] Whether or not the account has been vaulted
    # @param privacy [Boolean] The users privacy status
    # @return [email]
    # @note this will also cause the previous email address to become an alias
    def perform(id, first_name, last_name, address, uuid, password, vfe, privacy)
      email = PersonEmail.find(id)
      old_address = email.address.dup
      new_address = address
      old_uuid = email.uuid.try(:dup).presence
      new_uuid = uuid.presence

      google_params = Hash(first_name: first_name, last_name: last_name, password: password, address: address, privacy: privacy).reject{|k, v| v.blank? }

      Log.info %{Update PersonEmail address from "#{email}" to [id: "#{id}", first_name: "#{first_name}", last_name: "#{last_name}", address: "#{address}", uuid: "#{uuid}", password: "#{password}", vfe: "#{vfe}", privacy: "#{privacy}"]}

      if Enabled.write?
        GoogleAccount.new(old_address).update! google_params
        email.update! address: address, vfe: vfe, uuid: uuid

        if old_uuid != new_uuid
          Workers::Trogdir::DeleteEmail.perform_async old_uuid, email_hash['id']
          if new_uuid.present?
            Workers::Trogdir::CreateEmail.perform_async new_uuid, new_address
          end
# TODO: this needs to perhaps change the email as well. maybe create seperate methods
          if update_legacy? old_uuid
            new_biola_id = TrogdirPerson.new(new_uuid).biola_id
            Workers::LegacyEmailTable::UpdateID.perform_async(biola_id, new_biola_id)
          end

        elsif old_address != new_address
          Workers::Trogdir::RenameEmail.perform_async old_uuid, new_uuid, old_address, new_address
          AliasEmail.create! account_email: email, address: new_address
          if update_legacy? old_uuid
            Workers::LegacyEmailTable::Rename.perform_async(biola_id, old_address, new_address)
          end
        end

        end
      end

      email
    end

    private
    def update_legacy?(old_uuid)
      old_uuid.present? && biola_id = TrogdirPerson.new(old_uuid).biola_id
    end
  end
end
