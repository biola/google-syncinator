FactoryGirl.define do
  factory :department_email, class: DepartmentEmail, parent: :account_email do
    uuids { [SecureRandom.uuid] }
  end
end
