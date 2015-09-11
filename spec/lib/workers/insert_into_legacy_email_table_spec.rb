require 'spec_helper'

describe Workers::LegacyEmailTable::Insert, type: :unit do
  let(:biola_id) { 1234567 }
  let(:email) { 'bob.dole@biola.edu' }

  after { DB[:email].truncate }

  it 'inserts a record into the email table' do
    expect { Workers::LegacyEmailTable::Insert.new.perform(biola_id, email) }.to change { DB[:email].count }.from(0).to 1
  end
end
