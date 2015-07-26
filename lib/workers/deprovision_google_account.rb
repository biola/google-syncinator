module Workers
  class DeprovisionGoogleAccount
    include Sidekiq::Worker

    # Pretty basic worker obviously, it's really just here so we can schedule jobs for the future
    def perform(change_hash)
      change = TrogdirChange.new(change_hash)
      ServiceObjects::DeprovisionGoogleAccount.new(change).call
    end
  end
end
