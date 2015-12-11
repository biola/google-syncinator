require 'spec_helper'

describe AccountEmail, type: :unit do
  let(:address) { 'bob.dole@biola.edu' }

  it { is_expected.to embed_many(:deprovision_schedules) }
  it { is_expected.to embed_many(:exclusions) }
  it { is_expected.to have_many(:alias_emails) }
  it { is_expected.to have_fields(:address, :state) }
  it { is_expected.to be_timestamped_document }

  it { is_expected.to validate_presence_of(:address) }
  it { is_expected.to validate_presence_of(:state) }
  it { is_expected.to validate_inclusion_of(:state).to_allow(:active, :suspended, :deleted) }

  describe '#notification_recipients' do
    it 'is not implemented' do
      expect { subject.notification_recipients }.to raise_error(NotImplementedError)
    end
  end

  describe '#excluded?' do
    let(:creator_uuid) { '00000000-0000-0000-0000-000000000000' }
    let(:now) { Time.now }
    let(:starts_at) { now - 1 }
    let(:ends_at) { nil }
    before { subject.exclusions.build creator_uuid: creator_uuid, starts_at: starts_at, ends_at: ends_at }

    context 'when starts_at is in the future' do
      let(:starts_at) { 1.day.from_now }
      it { expect(subject.excluded?).to be false }
    end

    context 'when starts_at is in the past' do
      context 'when ends_at is nil' do
        it { expect(subject.excluded?).to be true }
      end

      context 'when ends_at is in the past' do
        let(:ends_at) { now - 1 }
        it { expect(subject.excluded?).to be false }
      end

      context 'when ends_at is in the future' do
        let(:ends_at) { now + 1 }
        it { expect(subject.excluded?).to be true }
      end
    end
  end

  describe 'after_save' do
    let(:account_email) { create :account_email, address: address }
    let!(:alias_email) { create :alias_email, account_email: account_email }

    it 'updates the state of associated alias emails' do
      expect { account_email.update state: 'deleted' }.to change { alias_email.reload.state }.from(:active).to :deleted
    end

    context 'when AliasEmail is deleted' do
      before { alias_email.update! state: :deleted }

      it 'does not update the state of associated alias emails' do
        expect { account_email.update state: :suspended }.to_not change { alias_email.reload.state }
      end
    end
  end
end
