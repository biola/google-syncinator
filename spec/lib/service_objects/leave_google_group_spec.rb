require 'spec_helper'

describe ServiceObjects::LeaveGoogleGroup do
  let(:fixture) { 'leave_group' }
  let(:change_hash) { JSON.parse(File.read("./spec/fixtures/#{fixture}.json")) }
  let(:trogdir_change) { TrogdirChange.new(change_hash) }
  subject { ServiceObjects::LeaveGoogleGroup.new(trogdir_change) }

  describe '#call' do
    context 'with no whitelisted groups' do
      before { expect(Settings).to receive_message_chain(:groups, :whitelist).and_return ['Republican', 'Candidate'] }
      it { expect(subject.call).to eql :skip }
    end

    context 'with whitelisted groups' do
      before { expect(Settings).to receive_message_chain(:groups, :whitelist).and_return ['Republican', 'Congressman'] }

      it do
        expect(subject).to receive_message_chain(:google_account, :leave!).with 'Congressman'
        expect(subject.call).to eql :update
      end
    end
  end

  describe '#ignore?' do
    context 'when a whitelisted group is left' do
      before { expect(Settings).to receive_message_chain(:groups, :whitelist).and_return ['Republican', 'Congressman'] }
      it { expect(subject.ignore?).to be false }
    end

    context 'when a non-whitelisted group is left' do
      before { expect(Settings).to receive_message_chain(:groups, :whitelist).and_return ['Republican', 'Candidate'] }
      it { expect(subject.ignore?).to be true }
    end

    context 'when no group is left' do
      let(:fixture) { 'update_email' }
      it { expect(subject.ignore?).to be true }
    end
  end
end
