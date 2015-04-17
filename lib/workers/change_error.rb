module Workers
  class ChangeError
    include Sidekiq::Worker

    def perform(sync_log_id, message)
      response = trogdir.error(sync_log_id: sync_log_id, message: message).perform
      raise "Error: #{response.parse['error']}" unless response.success?
    end

    private

    def trogdir
      Trogdir::APIClient::ChangeSyncs.new
    end
  end
end
