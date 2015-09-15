require 'spec_helper'

describe UniversityEmail, type: :unit do
  let(:uuid) { '00000000-0000-0000-0000-000000000000' }
  let(:address) { 'bob.dole@biola.edu' }

  it { is_expected.to embed_many(:deprovision_schedules) }
  it { is_expected.to embed_many(:exclusions) }
  it { is_expected.to have_fields(:uuid, :address, :primary, :state) }
  it { is_expected.to be_timestamped_document }

  it { is_expected.to validate_presence_of(:uuid) }
  it { is_expected.to validate_presence_of(:address) }
  it { is_expected.to validate_presence_of(:primary) }
  it { is_expected.to validate_presence_of(:state) }
  it { is_expected.to validate_uniqueness_of(:address).scoped_to(:uuid) }
  it { is_expected.to validate_inclusion_of(:state).to_allow(:active, :suspended, :deleted) }

  describe 'validation' do
    context 'when the email address already exists' do
      before { UniversityEmail.create(uuid: '11111111-1111-1111-1111-111111111111', address: address, state: state)}
      subject { UniversityEmail.new uuid: uuid, address: address }

      context 'when the email is active' do
        let(:state) { :active }

        it 'is invalid' do
          expect(subject).to be_invalid
        end
      end

      context 'when the email is suspended' do
        let(:state) { :suspended }

        it 'is invalid' do
          expect(subject).to be_invalid
        end
      end

      context 'when the email is deleted' do
        let(:state) { :deleted }

        it 'is valid' do
          expect(subject).to be_valid
        end
      end
    end
  end

  describe '#disable_date' do
    subject { UniversityEmail.new(uuid: uuid, address: address) }

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
      subject { UniversityEmail.new(uuid: uuid, address: address, created_at: 29.days.ago) }
      it { expect(subject.protected?).to be true }
    end

    context 'when created at is a long time ago' do
      subject { UniversityEmail.new(uuid: uuid, address: address, created_at: 31.days.ago) }
      it { expect(subject.protected?).to be false }
    end
  end

  describe '#protected_until' do
    let(:now) { Time.now }
    subject { UniversityEmail.new(uuid: uuid, address: address, created_at: created_at) }

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
    let(:now) { Time.now }
    let(:starts_at) { now - 1 }
    let(:ends_at) { nil }
    before { subject.exclusions.build creator_uuid: uuid, starts_at: starts_at, ends_at: ends_at }

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
    subject { UniversityEmail.create(uuid: uuid, address: address) }

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
    let!(:email) { UniversityEmail.create! uuid: uuid, address: address }
    let!(:completed) { email.deprovision_schedules.create(action: :notify_of_inactivity, scheduled_for: 1.day.ago, completed_at: 1.day.ago) }
    let!(:incomplete) { email.deprovision_schedules.create(action: :notify_of_inactivity, scheduled_for: 1.day.ago, job_id: '123') }

    before { expect(Sidekiq::Status).to receive(:cancel).once.with('123') }

    it { expect { email.cancel_deprovisioning! }.to_not change { completed } }
    it { expect { email.cancel_deprovisioning! }.to change { incomplete.canceled? }.from(false).to true }
  end

  describe '#to_s' do
    subject { UniversityEmail.new(uuid: uuid, address: address) }

    it 'returns a string of the uuid and the address' do
      expect(subject.to_s).to eql '00000000-0000-0000-0000-000000000000/bob.dole@biola.edu'
    end
  end

  describe '.current' do
    context 'without a record' do
      it { expect(UniversityEmail.current(address)).to be nil }
    end

    context 'with a record' do
      before { UniversityEmail.create uuid: uuid, address: 'bob.dole@biola.edu', state: state }

      context 'when active' do
        let(:state) { :active }
        it { expect(UniversityEmail.current(address)).to be_a UniversityEmail }
      end

      context 'with a suspended record' do
        let(:state) { :suspended }
        it { expect(UniversityEmail.current(address)).to be_a UniversityEmail }
      end

      context 'with deleted record' do
        let(:state) { :deleted }
        it { expect(UniversityEmail.current(address)).to be nil }
      end
    end
  end

  describe '.active?' do
    subject { UniversityEmail }

    context 'when no emails' do
      it { expect(subject.active?(uuid)).to be false }
    end

    context 'when an suspended email' do
      before { subject.create uuid: uuid, address: address, state: :suspended }
      it { expect(subject.active?(uuid)).to be false }
    end

    context 'when an active email' do
      before { subject.create uuid: uuid, address: address, state: :active }
      it { expect(subject.active?(uuid)).to be true }
    end
  end

  describe '.available?' do
    subject { UniversityEmail }

    context "when email doesn't exist" do
      it { expect(subject.available?(address)).to be true }
    end

    context 'when email is suspended' do
      before { subject.create uuid: uuid, address: address, state: :suspended }
      it { expect(subject.available?(address)).to be false }
    end

    context 'when email is deleted' do
      before { subject.create uuid: uuid, address: address, state: :deleted }
      it { expect(subject.available?(address)).to be true }
    end
  end

  describe '.find_reprovisionable' do
    let(:uuid) { '00000000-0000-0000-0000-000000000000' }
    context 'when person has no emails' do
      it { expect(UniversityEmail.find_reprovisionable(uuid)).to be nil }
    end

    context 'when person has an active email' do
      let!(:email) { UniversityEmail.create uuid: uuid, address: address, primary: true, state: :active }
      it { expect(UniversityEmail.find_reprovisionable(uuid)).to be nil }
    end

    context 'when person has a suspended email' do
      let!(:email) { UniversityEmail.create uuid: uuid, address: address, primary: true, state: :suspended }
      it { expect(UniversityEmail.find_reprovisionable(uuid)).to eql email }
    end

    context 'when person has a deleted email' do
      let!(:email) { UniversityEmail.create uuid: uuid, address: address, primary: true, state: :deleted }
      it { expect(UniversityEmail.find_reprovisionable(uuid)).to eql email }
    end
  end
end