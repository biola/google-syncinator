FactoryGirl.define do
  factory :account_email, class: AccountEmail, parent: UniversityEmail do
    exclusions []
    alias_emails []
  end
end
