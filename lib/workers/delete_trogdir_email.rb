module Workers
  class DeleteTrogdirEmail
    include Sidekiq::Worker

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
    end
  end
end
