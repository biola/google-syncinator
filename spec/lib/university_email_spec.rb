require 'spec_helper'

describe UniversityEmail do
  let(:uuid) { '00000000-0000-0000-0000-000000000000' }

  it { is_expected.to embed_many(:deprovision_schedules) }
  it { is_expected.to have_fields(:uuid, :address, :primary, :state) }
  it { is_expected.to be_timestamped_document }

  it { is_expected.to validate_presence_of(:uuid) }
  it { is_expected.to validate_presence_of(:address) }
  it { is_expected.to validate_presence_of(:primary) }
  it { is_expected.to validate_presence_of(:state) }
  it { is_expected.to validate_uniqueness_of(:address).scoped_to(:uuid) }
  it { is_expected.to validate_inclusion_of(:state).to_allow(:active, :suspended, :deleted) }

  describe '#disable_date' do
    subject { UniversityEmail.new(uuid: uuid, address: 'test@example.com') }

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

  describe '#cancel_deprovisioning!' do
    let!(:email) { UniversityEmail.create! uuid: uuid, address: 'test@example.com' }
    let!(:completed) { email.deprovision_schedules.create(action: :notify_of_inactivity, scheduled_for: 1.day.ago, completed_at: 1.day.ago) }
    let!(:incomplete) { email.deprovision_schedules.create(action: :notify_of_inactivity, scheduled_for: 1.day.ago, job_id: '123') }

    before { expect(Sidekiq::Status).to receive(:cancel).once.with('123') }

    it { expect { email.cancel_deprovisioning! }.to_not change { completed } }
    it { expect { email.cancel_deprovisioning! }.to change { incomplete.canceled? }.from(false).to true }
  end

  describe '.active?' do
    subject { UniversityEmail }
    context 'when no emails' do
      it { expect(subject.active?(uuid)).to be false }
    end

    context 'when an suspended email' do
      before { subject.create uuid: uuid, address: 'test@example.com', state: :suspended }
      it { expect(subject.active?(uuid)).to be false }
    end

    context 'when an active email' do
      before { subject.create uuid: uuid, address: 'test@example.com', state: :active }
      it { expect(subject.active?(uuid)).to be true }
    end
  end

  describe '.available?' do
    let(:uuid) { '00000000-0000-0000-0000-000000000000' }
    let(:address) { 'bob.dole@biola.edu' }

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
      let!(:email) { UniversityEmail.create uuid: uuid, address: 'test@example.com', primary: true, state: :active }
      it { expect(UniversityEmail.find_reprovisionable(uuid)).to be nil }
    end

    context 'when person has a suspended email' do
      let!(:email) { UniversityEmail.create uuid: uuid, address: 'test@example.com', primary: true, state: :suspended }
      it { expect(UniversityEmail.find_reprovisionable(uuid)).to eql email }
    end

    context 'when person has a deleted email' do
      let!(:email) { UniversityEmail.create uuid: uuid, address: 'test@example.com', primary: true, state: :deleted }
      it { expect(UniversityEmail.find_reprovisionable(uuid)).to eql email }
    end
  end
end
