module Workers
  class ChangeFinish
    include Sidekiq::Worker

    def perform(sync_log_id, action_taken)
      response = trogdir.finish(sync_log_id: sync_log_id, action: action_taken).perform
      raise "Error: #{response.parse['error']}" unless response.success?
    end

    private

    def trogdir
      Trogdir::APIClient::ChangeSyncs.new
    end
  end
end
