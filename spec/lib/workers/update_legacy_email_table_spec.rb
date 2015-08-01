require 'spec_helper'

describe Workers::UpdateLegacyEmailTable, type: :unit do
  let(:biola_id) { 1234567 }
  let(:old_email) { 'bobby.dole@biola.edu' }
  let(:new_email) { 'bob.dole@biola.edu' }

  let!(:old_record) { DB[:email].insert idnumber: biola_id, email: old_email, primary: 1 }
  after { DB[:email].truncate }

  it 'marks the old email as not primary' do
    expect { subject.perform(biola_id, old_email, new_email) }.to change { DB[:email].where(email: old_email).first[:primary] }.from(1).to 0
  end

  context 'when new record already exists' do
    let!(:new_record) { DB[:email].insert idnumber: biola_id, email: new_email, primary: 0, expiration_date: 1.day.ago }

    it 'updates the primary field' do
      expect { subject.perform(biola_id, old_email, new_email) }.to change { DB[:email].where(email: new_email).first[:primary] }.from(0).to 1
    end

    it 'updates the expiration_date field' do
      expect { subject.perform(biola_id, old_email, new_email) }.to change { DB[:email].where(email: new_email).first[:expiration_date] }.to nil
    end
  end

  context 'when new record does not already exists' do
    it 'inserts the record' do
      expect { subject.perform(biola_id, old_email, new_email) }.to change { DB[:email].where(email: new_email).count }.from(0).to 1
    end
  end
end
