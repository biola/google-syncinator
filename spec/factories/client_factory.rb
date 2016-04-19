FactoryGirl.define do
  factory :client, class: Client do
    name { Faker::Internet.domain_name }
    slug { name.parameterize }
    access_id { rand(2**(0.size * 8 - 2) - 1) }
    secret_key { ApiAuth.generate_secret_key }
    active true
  end
end
