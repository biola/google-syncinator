module Workers
  # Scheduled Sidekiq worker to proccess changes fro Trogdir
  class HandleChanges
    include Sidekiq::Worker

    # Exception for when an error occurs with Trogdir
    class TrogdirAPIError < StandardError; end

    sidekiq_options retry: false

    # Get the queued changes from Trogdir and pass them off to
    # Workers::HandleChange to process asynchronously
    # @return [nil]
    def perform
      Log.info "[#{jid}] Starting Google Syncinator Handle Changes job"

      # TODO: if Trogdir ever gets a dry run feature for starting change syncs, it should be used here
      hashes = []
      response = []

      begin
        loop do
          response = change_syncs.start(limit: 10).perform
          break if response.parse.blank?
          raise TrogdirAPIError, response.parse['error'] unless response.success?

          hashes += Array(response.parse)
        end
      rescue StandardError
        Log.error "Error in HandleChanges: #{response.inspect}"
      end

      # Keep processing batches until we run out
      changes_processed = if hashes.any?
        Log.info "[#{jid}] Processing #{hashes.length} changes"

        hashes.each do |hash|
          Workers::HandleChange.perform_async(hash)
        end
      end

      Log.info "[#{jid}] Finished job"

      # Run the worker again since there is probably more to process
      if changes_processed
        HandleChanges.perform_async
      end

      nil
    end

    private

    # Wrapper for the Trogdir change syncs API object
    # @return [Trogdir::APIClient::ChangeSyncs]
    def change_syncs
      ::Trogdir::APIClient::ChangeSyncs.new
    end
  end
end

