module Workers
  module Trogdir
    # Sidekiq worker that sends an error status to Trogdir
    class ChangeError
      include Sidekiq::Worker

      sidekiq_options retry: false

      # Sends an error status to Trogdir
      # @param sync_log_id [String] sync log ID from Trogdir
      # @param message [String] error message
      def perform(sync_log_id, message)
        response = trogdir.error(sync_log_id: sync_log_id, message: message).perform
        raise "Error: #{response.parse['error']}" unless response.success?
        Log.info "Reported error on sync log #{sync_log_id} with an message of #{message}"
      end

      private

      # Wrapper for the Trogdir change syncs API object
      # @return [Trogdir::APIClient::ChangeSyncs]
      def trogdir
        ::Trogdir::APIClient::ChangeSyncs.new
      end
    end
  end
end
