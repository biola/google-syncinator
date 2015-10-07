module Workers
  # Scheduled Sidekiq worker that check for Google accounts that are not
  #   required and have become inactive and schedule them for deprovisioning
  class CheckInactive
    include Sidekiq::Worker
    include ActivityCheck

    # Find inactive Google accounts and schedule them to be deprovisioned
    # @return [nil]
    def perform
      run_activity_check(:inactive)
    end
  end
end
