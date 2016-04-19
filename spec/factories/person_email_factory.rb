FactoryGirl.define do
  factory :person_email, class: PersonEmail, parent: :account_email do
    uuid { SecureRandom.uuid }
  end
end
