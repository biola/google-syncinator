require 'spec_helper'

describe ServiceObjects::UpdateEmailAddress do
  let(:fixture) { 'update_email' }
  let(:change_hash) { JSON.parse(File.read("./spec/fixtures/#{fixture}.json")) }
  let(:trogdir_change) { TrogdirChange.new(change_hash) }
  subject { ServiceObjects::UpdateEmailAddress.new(trogdir_change) }

  describe '#call' do
    it 'update the legacy email table' do
      expect_any_instance_of(TrogdirPerson).to receive(:biola_id).and_return 1234567
      expect(Workers::UpdateLegacyEmailTable).to receive(:perform_async).with 1234567, 'bobby.dole@biola.edu', 'bob.dole@biola.edu'
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
