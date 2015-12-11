FactoryGirl.define do
  factory :deprovision_schedule, class: DeprovisionSchedule do
    university_email
    action { :suspend }
    scheduled_for { 1.hour.from_now }
    canceled false
  end
end
