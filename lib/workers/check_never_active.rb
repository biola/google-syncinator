module Workers
  # Scheduled Sidekiq worker that check for Google accounts that are not
  #   required and have never been active and schedule them for deprovisioning
  class CheckNeverActive
    include Sidekiq::Worker
    include ActivityCheck

    # Find never active Google accounts and schedule them to be deprovisioned
    # @return [nil]
    def perform
      run_activity_check(:never_active)
    end
  end
end
