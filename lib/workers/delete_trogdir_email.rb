module Workers
  # Sidekiq worker that deletes an email record in Trogdir
  class DeleteTrogdirEmail
    include Sidekiq::Worker

    # Delete an email record in Trogdir
    # @param uuid [String] UUID of the person who owns the email address
    # @param email_address [String] email address to delete
    # @return [nil]
    def perform(uuid, email_address)
      index_response = Trogdir::APIClient::Emails.new.index(uuid: uuid).perform
      raise TrogdirAPIError, index_response.parse['error'] unless index_response.success?

      email_hash = index_response.parse.find { |e| e['address'] == email_address }

      # This is meant to idempotently ensure the email is deleted since it may be run
      # both at suspension and deletion. So fail silently if the email doesn't exist.
      unless email_hash.nil?
        if !Settings.dry_run?
          destroy_response = Trogdir::APIClient::Emails.new.destroy(uuid: uuid, email_id: email_hash['id']).perform
          raise TrogdirAPIError, destroy_response.parse['error'] unless destroy_response.success?
        end

        Log.info "Deleted Trogdir email #{email_address} for person #{uuid}"
      end

      nil
    end
  end
end
