module Workers
  # Update the email account in all the university_emails collection,
  #   Trogdir and the legacy email table
  class UpdatePersonEmail
    include Sidekiq::Worker

    # @!attribute [r] id
    #   @return [ID] the id of the account
    attr_reader :id

    # @!attribute [r] new_uuid
    #   @return [UUID] the new uuid of the account
    attr_reader :new_uuid

    # @!attribute [r] new_address
    #   @return [NewAddress] the new_address of the account
    attr_reader :new_address

    # @!attribute [r] first_name
    #   @return [FirstName] the first_name of the account
    attr_reader :first_name

    # @!attribute [r] last_name
    #   @return [LastName] the last_name of the account
    attr_reader :last_name

    # @!attribute [r] password
    #   @return [Password] the password of the account
    attr_reader :password

    # @!attribute [r] vfe
    #   @return [VFE] the vfe value of the account
    attr_reader :vfe

    # @!attribute [r] privacy
    #   @return [Privacy] the privacy of the account
    attr_reader :privacy

    # @param uuid [String] The users uuid from Trogdir
    # @param first_name [String] The users first name
    # @param last_name [String] The users last name
    # @param address [String] The users email address
    # @param password [String] The users new password
    # @param vfe [Boolean] Whether or not the account has been vaulted
    # @param privacy [Boolean] The users privacy status
    def initialize(id: nil, uuid: nil, address: nil, first_name: nil, last_name: nil, password: nil, vfe: nil, privacy: nil)
      @id = id
      @new_uuid = uuid.presence
      @new_address = address
      @first_name = first_name
      @last_name = last_name
      @password = password
      @vfe = vfe
      @privacy = privacy
    end

    # Update the email account in all the university_emails collection,
    #   Trogdir and the legacy email table
    # @return [email]
    # @note this will also cause the previous address to become an alias if it has changed
    def perform
      email = PersonEmail.find(id)
      old_address = email.address.dup
      google_address = (new_address == old_address ? nil : new_address)
      old_uuid = email.uuid.try(:dup).presence
      old_biola_id = biola_id(old_uuid) if old_uuid.present?
      new_biola_id = biola_id(new_uuid) if new_uuid.present?

      google_params = Hash( first_name: first_name, last_name: last_name, password: password, address: google_address, privacy: privacy ).reject{|k, v| v.nil? || v.try(:empty?) }

      Log.info %{Update PersonEmail address from "#{email}" to "#{google_params.merge(uuid: new_uuid, vfe: vfe).except(:password)}"}

      if Enabled.write?
        GoogleAccount.new(old_address).update!(google_params) unless google_params.empty?
        email.update! address: new_address, vfe: vfe, uuid: new_uuid
        if old_address != new_address
          AliasEmail.create! account_email: email, address: old_address
          if old_uuid.present?
            Workers::LegacyEmailTable::Rename.perform_async(old_biola_id, old_address, new_address)
          end
        end

        if old_uuid != new_uuid
          Workers::Trogdir::DeleteEmail.perform_async old_uuid, old_address
          if new_uuid.present?
            Workers::Trogdir::CreateEmail.perform_async new_uuid, new_address
            if old_uuid.present?
              Workers::LegacyEmailTable::UpdateID.perform_async(old_biola_id, new_biola_id)
            end
          elsif old_uuid.present?
            Workers::LegacyEmailTable::Expire.perform_async(old_biola_id, old_address)
          end
        elsif old_address != new_address
          Workers::Trogdir::RenameEmail.perform_async old_uuid, new_uuid, old_address, new_address
        end
      end

      email
    end

    private
    def biola_id(uuid)
      TrogdirPerson.new(uuid).biola_id
    end
  end
end
