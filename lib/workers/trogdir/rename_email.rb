module Workers
  module Trogdir
    # Sidekiq worker that renames an email record in Trogdir
    class RenameEmail
      include Sidekiq::Worker

      # Rename an email record in Trogdir
      # @param uuid [String] UUID of the person who owns the email address
      # @param old_address [String] existing email address to be renamed
      # @param new_address [String] new email address
      # @return [nil]
      def perform(uuid, old_address, new_address)
        index_response = ::Trogdir::APIClient::Emails.new.index(uuid: uuid).perform
        raise TrogdirAPIError, index_response.parse['error'] unless index_response.success?

        email_hash = index_response.parse.find { |e| e['address'] == old_address }
        raise TrogdirAPIError, %{Email with address #{old_address} for uuid: "#{uuid}" could not be found} if email_hash.nil?

        if Enabled.write?
          update_response = ::Trogdir::APIClient::Emails.new.update(uuid: uuid, email_id: email_hash['id'], address: new_address).perform
          raise TrogdirAPIError, update_response.parse['error'] unless update_response.success?
        end

        Log.info "Renamed Trogdir email #{old_address} to #{new_address} for person #{uuid}"

        nil
      end
    end
  end
end
