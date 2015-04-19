module Workers
  class HandleChanges
    include Sidekiq::Worker
    include Sidetiq::Schedulable

    class TrogdirAPIError < StandardError; end

    sidekiq_options retry: false

    recurrence do
      hourly.hour_of_day(*(8..20).to_a).day(:monday, :tuesday, :wednesday, :thursday, :friday)
    end

    def perform
      Log.info "[#{jid}] Starting job"

      response = change_syncs.start.perform
      raise TrogdirAPIError, response.parse['error'] unless response.success?

      hashes = Array(response.parse)

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
    end

    private

    def change_syncs
      Trogdir::APIClient::ChangeSyncs.new
    end
  end
end
