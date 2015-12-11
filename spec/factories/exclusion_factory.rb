FactoryGirl.define do
  factory :exclusion, class: Exclusion do
    account_email
    creator_uuid { SecureRandom.uuid }
    starts_at { Time.now }
  end
end
