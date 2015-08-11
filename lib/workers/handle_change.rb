module Workers
  # Sidekiq worker to handle a Trogdir change
  class HandleChange
    include Sidekiq::Worker

    # Exception for when an error occurs with Trogdir
    class TrogdirAPIError < StandardError; end

    sidekiq_options retry: false

    # Simple wrapper for ServiceObjects::HandleChange. This worker is here just
    #   so that the service object can be fired asynchronously
    # @param change_hash [Hash] a change hash from Trogdir
    # @return [nil]
    def perform(change_hash)
      change = TrogdirChange.new(change_hash)
      ServiceObjects::HandleChange.new(change).call
    end
  end
end
