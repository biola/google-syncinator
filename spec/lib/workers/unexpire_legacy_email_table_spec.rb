require 'spec_helper'

describe Workers::UnexpireLegacyEmailTable, type: :unit do
  let(:biola_id) { 1234567 }
  let(:email) { 'bob.dole@biola.edu' }

  before { DB[:email].insert idnumber: biola_id, email: email, expiration_date: 3.days.ago, reusable_date: 4.days.from_now }
  after { DB[:email].truncate }

  it 'updates expiration_date and rusable_date' do
    expect { subject.perform(biola_id, email) }.to change { DB[:email].select_map([:expiration_date, :reusable_date]).first }.to [nil, nil]
  end
end
