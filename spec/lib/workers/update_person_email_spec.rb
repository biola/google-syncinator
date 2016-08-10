require 'spec_helper'

describe Workers::UpdatePersonEmail do
  let(:old_uuid) { '00000000-0000-0000-0000-000000000000' }
  let(:new_uuid) { '00000000-0000-0000-0000-000000000001' }
  let(:old_address) { 'bob.dole@biola.edu' }
  let(:new_address) { 'bobby.dole@biola.edu' }
  let(:biola_id) { 1234567 }
  let(:new_biola_id) { 2345678 }
  let(:vfe) { true }
  let(:password) { 'totallyrandompassword' }
  let(:first_name) { 'Shiva' }
  let(:last_name) { 'Ayyadurai' }
  let(:privacy) { false }
  let(:google_params) { { first_name: first_name, last_name: last_name, password: password, address: new_address, privacy: privacy } }
  let!(:email) { create :person_email, uuid: old_uuid, address: old_address }
  subject { Workers::UpdatePersonEmail }

  before do
    allow(TrogdirPerson).to receive(:new).with(old_uuid).and_return double(biola_id: biola_id)
    allow(TrogdirPerson).to receive(:new).with(new_uuid).and_return double(biola_id: new_biola_id)
    expect_any_instance_of(GoogleAccount).to receive(:update!).with google_params
  end

  context 'a new email' do
    it 'updates the person email' do
      expect { subject.new(email.id, new_uuid, new_address, first_name, last_name, password, vfe, privacy).perform }.to change { email.reload.address }.from(old_address).to new_address
    end

    it 'updates the trogdir email' do
      expect { subject.new(email.id, old_uuid, new_address, first_name, last_name, password, vfe, privacy).perform}.to change(Workers::Trogdir::RenameEmail.jobs, :size).by(1)
    end

    it 'updates the legacy table' do
      expect { subject.new(email.id, new_uuid, new_address, first_name, last_name, password, vfe, privacy).perform}.to change(Workers::LegacyEmailTable::Rename.jobs, :size).by(1)
    end
  end

  context 'a new owner' do
    it 'deletes the email from the old owner in trogdir' do
      expect { subject.new(email.id, new_uuid, new_address, first_name, last_name, password, vfe, privacy).perform}.to change(Workers::Trogdir::DeleteEmail.jobs, :size).by(1)
    end

    it 'creates a new email under the new owner in trogdir when new_uuid present' do
      expect { subject.new(email.id, new_uuid, new_address, first_name, last_name, password, vfe, privacy).perform}.to change(Workers::Trogdir::CreateEmail.jobs, :size).by(1)
    end

    it 'does not create a new email in trogdir if the new_uuid is not present' do
      expect { subject.new(email.id, '', new_address, first_name, last_name, password, vfe, privacy).perform}.to change(Workers::Trogdir::CreateEmail.jobs, :size).by(0)
    end

    it 'updates the owner in the legacy table if the old and new uuid is present and different' do
      expect { subject.new(email.id, new_uuid, new_address, first_name, last_name, password, vfe, privacy).perform}.to change(Workers::LegacyEmailTable::UpdateID.jobs, :size).by(1)
    end

    it 'expires the email in the legacy table if the old uuid is present but the new uuid is not' do
      expect { subject.new(email.id, '', new_address, first_name, last_name, password, vfe, privacy).perform}.to change(Workers::LegacyEmailTable::Expire.jobs, :size).by(1)
    end

    it 'does not rename the email in the legacy table if the old uuid is present but the new uuid is not' do
      expect { subject.new(email.id, '', new_address, first_name, last_name, password, vfe, privacy).perform}.to change(Workers::LegacyEmailTable::UpdateID.jobs, :size).by(0)
    end
  end
end
