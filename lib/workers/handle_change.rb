module Workers
  class HandleChange
    include Sidekiq::Worker

    class TrogdirAPIError < StandardError; end

    sidekiq_options retry: false

    def perform(change_hash)
      change = TrogdirChange.new(change_hash)
      ServiceObjects::HandleChange.new(change).call
    end
  end
end
