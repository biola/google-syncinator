FactoryGirl.define do
  factory :university_email, class: UniversityEmail do
    address { Faker::Internet.email }
    state  :active
    deprovision_schedules { [] }
    created_at Settings.deprovisioning.protect_for + 1.day
  end
end
