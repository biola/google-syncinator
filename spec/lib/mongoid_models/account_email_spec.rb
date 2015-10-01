require 'spec_helper'

describe AccountEmail, type: :unit do
  let(:address) { 'bob.dole@biola.edu' }

  it { is_expected.to embed_many(:deprovision_schedules) }
  it { is_expected.to embed_many(:exclusions) }
  it { is_expected.to have_fields(:address, :state) }
  it { is_expected.to be_timestamped_document }

  it { is_expected.to validate_presence_of(:address) }
  it { is_expected.to validate_presence_of(:state) }
  it { is_expected.to validate_inclusion_of(:state).to_allow(:active, :suspended, :deleted) }

  describe '#disable_date' do
    subject { AccountEmail.new(address: address) }

    context 'when no deprovision_schedules' do
      it { expect(subject.disable_date).to be nil }
    end

    context 'when only delete is scheduled' do
      before { subject.deprovision_schedules.build action: :delete, scheduled_for: 1.day.from_now.end_of_day }

      it 'uses the delete time' do
        expect(subject.disable_date.to_time).to eql 1.day.from_now.end_of_day
      end
    end

    context 'when suspend and delete is scheduled' do
      before do
        subject.deprovision_schedules.build action: :suspend, scheduled_for: 1.day.from_now.end_of_day
        subject.deprovision_schedules.build action: :delete, scheduled_for: 2.days.from_now.end_of_day
      end

      it "it uses the suspend time because it's scheduled first" do
        expect(subject.disable_date.to_time).to eql 1.day.from_now.end_of_day
      end
    end
  end

  describe '#protected?' do
    context 'when created_at is recent' do
      subject { AccountEmail.new(address: address, created_at: 29.days.ago) }
      it { expect(subject.protected?).to be true }
    end

    context 'when created at is a long time ago' do
      subject { AccountEmail.new(address: address, created_at: 31.days.ago) }
      it { expect(subject.protected?).to be false }
    end
  end

  describe '#protected_until' do
    let(:now) { Time.now }
    subject { AccountEmail.new(address: address, created_at: created_at) }

    context 'when created before the protection period' do
      let(:created_at) { now - Settings.deprovisioning.protect_for - 86400 }
      it { expect(subject.protected_until).to eql now - 86400 }
    end

    context 'when created within the protection peroid' do
      let(:created_at) { now - Settings.deprovisioning.protect_for + 86400 }
      it { expect(subject.protected_until).to eql now + 86400 }
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

  describe '#being_deprovisioned?' do
    subject { AccountEmail.create(address: address) }

    context 'when no deprovision schedules' do
      it { expect(subject.being_deprovisioned?).to be false }
    end

    context 'when completed deprovision schedules' do
      before { subject.deprovision_schedules.create action: :delete, scheduled_for: 1.day.ago, completed_at: 1.day.ago }
      it { expect(subject.being_deprovisioned?).to be false }
    end

    context 'when canceled deprovision schedules' do
      before { subject.deprovision_schedules.create action: :delete, scheduled_for: 1.day.from_now, canceled: true }
      it { expect(subject.being_deprovisioned?).to be false }
    end

    context 'when incomplete deprovision schedules' do
      before { subject.deprovision_schedules.create action: :delete, scheduled_for: 1.day.from_now }
      it { expect(subject.being_deprovisioned?).to be true }
    end
  end

  describe '#cancel_deprovisioning!' do
    let!(:email) { AccountEmail.create! address: address }
    let!(:completed) { email.deprovision_schedules.create(action: :notify_of_inactivity, scheduled_for: 1.day.ago, completed_at: 1.day.ago) }
    let!(:incomplete) { email.deprovision_schedules.create(action: :notify_of_inactivity, scheduled_for: 1.day.ago, job_id: '123') }

    before { expect(Sidekiq::Status).to receive(:cancel).once.with('123') }

    it { expect { email.cancel_deprovisioning! }.to_not change { completed } }
    it { expect { email.cancel_deprovisioning! }.to change { incomplete.canceled? }.from(false).to true }
  end

  describe 'after_save' do
    let(:account_email) { AccountEmail.create! address: address }
    let!(:alias_email) { AliasEmail.create! account_email: account_email, address: 'test@example.com' }

    it 'updates the state of associated alias emails' do
      expect { account_email.update state: 'deleted' }.to change { alias_email.reload.state }.from(:active).to :deleted
    end
  end
end
