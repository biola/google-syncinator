module Workers
  class CreateGoogleAppsAccounts
    include Sidekiq::Worker
    include Sidetiq::Schedulable

    sidekiq_options retry: false

    recurrence do
      hourly.hour_of_day(*(8..20).to_a).day(:monday, :tuesday, :wednesday, :thursday, :friday)
    end

    def perform
      # TODO: exclude from contact sharing if privacy == true
    end
  end
end
