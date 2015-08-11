module Workers
  # Sidekiq worker to deprovision a Google account
  class DeprovisionGoogleAccount
    include Sidekiq::Worker

    # Simple wrapper for `ServiceObjects::DeprovisionGoogleAccount`
    #   It's really here just so we can schedule jobs for the future
    # @return [nil]
    def perform(change_hash)
      change = TrogdirChange.new(change_hash)
      ServiceObjects::DeprovisionGoogleAccount.new(change).call

      nil
    end
  end
end
