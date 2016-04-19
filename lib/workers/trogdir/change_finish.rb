module Workers
  module Trogdir
    # Sidekiq worker that sends an finished status to Trogdir
    class ChangeFinish
      include Sidekiq::Worker

      sidekiq_options retry: false

      # Sends a finished status to Trogdir
      # @param sync_log_id [String] sync log ID from Trogdir
      # @param action_taken [String] the action that was taken
      def perform(sync_log_id, action_taken)
        if Enabled.write?
          response = trogdir.finish(sync_log_id: sync_log_id, action: action_taken).perform
          raise "Error: #{response.parse['error']}" unless response.success?
        end

        Log.info "Finished sync log #{sync_log_id} with an action of #{action_taken}"
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
