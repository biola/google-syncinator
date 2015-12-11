FactoryGirl.define do
  factory :alias_email, class: AliasEmail, parent: :university_email do
    account_email
  end
end
