require 'spec_helper'

describe ServiceObjects::SyncGoogleAccount do
  let(:fixture) { 'update_person' }
  let(:change_hash) { JSON.parse(File.read("./spec/fixtures/#{fixture}.json")) }
  let(:trogdir_change) { TrogdirChange.new(change_hash) }
  subject { ServiceObjects::SyncGoogleAccount.new(trogdir_change) }

  describe '#call' do
    let(:account) { instance_double(GoogleAccount, suspended?: false) }

    before do
      expect(TrogdirPerson).to receive(:new).and_return(double(first_or_preferred_name: 'Bob', last_name: 'Dole', department: 'Office of the president', title: 'POTUS', privacy: false))
      expect(account).to receive(:create_or_update!)
      expect(subject).to receive(:google_account).and_return(account).at_least(:once)
    end

    context 'when account suspended' do
      let(:account) { instance_double(GoogleAccount, suspended?: true) }

      before { expect(account).to receive(:suspended?).and_return true }

      it do
        expect(account).to receive(:unsuspend!)
        subject.call
      end
    end

    context 'when account active' do
      let(:account) { instance_double(GoogleAccount, suspended?: false) }

      before { expect(subject).to receive_message_chain(:google_account, :suspended?).and_return false }

      it do
        expect(account).to_not receive(:unsuspend!)
        subject.call
      end
    end
  end

  describe '#ignore?' do
    context 'when updating account info' do
      it { expect(subject.ignore?).to be false }
    end

    context 'when not updating account info' do
      let(:fixture) { 'update_person_ssn' }
      it { expect(subject.ignore?).to be true }
    end
  end
end
