require 'spec_helper'

describe ServiceObjects::JoinGoogleGroup, type: :unit do
  let(:fixture) { 'join_group' }
  let(:change_hash) { JSON.parse(File.read("./spec/fixtures/#{fixture}.json")) }
  let(:trogdir_change) { TrogdirChange.new(change_hash) }
  subject { ServiceObjects::JoinGoogleGroup.new(trogdir_change) }

  describe '#call' do
    context 'with no whitelisted groups' do
      before { expect(Settings).to receive_message_chain(:groups, :whitelist).and_return ['Republican', 'Candidate'] }
      it { expect(subject.call).to eql :skip }
    end

    context 'with whitelisted groups' do
      before { expect(Settings).to receive_message_chain(:groups, :whitelist).and_return ['Republican', 'President'] }

      it do
        expect(subject).to receive_message_chain(:google_account, :join!).with 'President'
        expect(subject.call).to eql :update
      end
    end
  end

  describe '#ignore?' do
    context 'when a whitelisted group is joined' do
      before { expect(Settings).to receive_message_chain(:groups, :whitelist).and_return ['Republican', 'President'] }
      it { expect(subject.ignore?).to be false }
    end

    context 'when a non-whitelisted group is joined' do
      before { expect(Settings).to receive_message_chain(:groups, :whitelist).and_return ['Republican', 'Candidate'] }
      it { expect(subject.ignore?).to be true }
    end

    context 'when no group is joined' do
      let(:fixture) { 'update_person' }
      it { expect(subject.ignore?).to be true }
    end
  end
end
