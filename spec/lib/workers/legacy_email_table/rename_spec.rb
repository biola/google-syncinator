require 'spec_helper'

describe Workers::LegacyEmailTable::Rename do
  let(:biola_id) { 1234567 }
  let(:old_address) { 'bob.dole@biola.edu' }
  let(:new_address) { 'bobby.dole@biola.edu' }

  before { DB[:email].insert idnumber: biola_id, email: old_address, primary: true }

  it 'marks the existing record not primary' do
    expect { subject.perform(biola_id, old_address, new_address) }.to change { DB[:email].first[:primary] }.from(1).to 0
  end

  it 'calls Workers::LegacyEmailTable::Insert' do
    expect {subject.perform(biola_id, old_address, new_address) }.to change { Workers::LegacyEmailTable::Insert.jobs.length }.from(0).to 1
  end
end
