require 'spec_helper'

describe ServiceObjects::UpdateEmailAddress, type: :unit do
  let(:uuid) { '00000000-0000-0000-0000-000000000000' }
  let(:old_address) { 'bobby.dole@biola.edu' }
  let(:new_address) { 'bob.dole@biola.edu' }
  let(:fixture) { 'update_email' }
  let(:change_hash) { JSON.parse(File.read("./spec/fixtures/#{fixture}.json")) }
  let(:trogdir_change) { TrogdirChange.new(change_hash) }
  subject { ServiceObjects::UpdateEmailAddress.new(trogdir_change) }

  describe '#call' do
    before do
      UniversityEmail.create! uuid: uuid, address: old_address, primary: true
      expect_any_instance_of(TrogdirPerson).to receive(:biola_id).and_return 1234567
      allow_any_instance_of(GoogleAccount).to receive(:rename!)
    end

    it 'updates the legacy email table' do
      expect(Workers::UpdateLegacyEmailTable).to receive(:perform_async).with 1234567, old_address, new_address
      expect(subject.call).to eql :update
    end

    it 'marks the old university email as not primary' do
      expect { subject.call }.to change { UniversityEmail.find_by(uuid: uuid, address: old_address).primary }.from(true).to false
    end

    it 'creates a university email with the new address' do
      expect { subject.call }.to change { UniversityEmail.where(uuid: uuid, address: new_address, primary: true).any? }.from(false).to true
    end

    it 'renames the Google account' do
      account = instance_double(GoogleAccount)
      expect(account).to receive(:rename!).with(new_address)
      expect(GoogleAccount).to receive(:new).with(old_address).and_return account
      expect(subject.call).to eql :update
    end
  end

  describe '#ignore?' do
    context 'when universiy email updated' do
      it { expect(subject.ignore?).to be false }
    end

    context 'when university email not updated' do
      let(:fixture) { 'update_person_ssn' }
      it { expect(subject.ignore?).to be true }
    end
  end
end
