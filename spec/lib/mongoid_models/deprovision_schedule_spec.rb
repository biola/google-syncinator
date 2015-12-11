require 'spec_helper'

describe DeprovisionSchedule, type: :unit do
  let(:uuid) { '00000000-0000-0000-0000-000000000000' }
  let(:address) { 'bob.dole@biola.edu' }
  let(:job_id) { '1234567890' }
  let(:person_email) { create :person_email, uuid: uuid, address: address }

  it { is_expected.to be_embedded_in(:university_email) }
  it { is_expected.to have_fields(:action, :reason, :scheduled_for, :completed_at, :canceled, :job_id) }
  it { is_expected.to be_timestamped_document }

  it { is_expected.to validate_presence_of(:action) }
  it { is_expected.to validate_presence_of(:scheduled_for) }
  it { is_expected.to validate_presence_of(:completed_at) }
  it { is_expected.to validate_inclusion_of(:action).to_allow(:notify_of_inactivity, :notify_of_closure, :suspend, :delete, :activate) }

  describe 'validate' do
    let(:alias_email) { create :alias_email, address: 'bobby.dole@biola.edu', account_email: person_email }
    subject { build :deprovision_schedule, university_email: alias_email, action: action, scheduled_for: 1.day.from_now }

    context 'when action is delete' do
      let(:action) { :delete }
      it { expect(subject).to be_valid }
    end

    context 'when action is not delete' do
      let(:action) { :suspend }
      it { expect(subject).to be_invalid }
    end
  end

  describe '#pending?' do
    context 'when completed_at and canceled blank' do
      subject { build :deprovision_schedule }
      it { expect(subject.pending?).to be true }
    end

    context 'when completed_at is set' do
      subject { build :deprovision_schedule, completed_at: 1.day.ago }
      it { expect(subject.pending?).to be false }
    end

    context 'when canceled is true' do
      subject { build :deprovision_schedule, canceled: true }
      it { expect(subject.pending?).to be false }
    end
  end

  describe '#create_and_schedule!' do
    subject { person_email.deprovision_schedules.build action: :delete, scheduled_for: 1.day.ago }

    it 'crease a deprovision schedule' do
      expect { subject.save_and_schedule! }.to change { person_email.deprovision_schedules.count }.from(0).to 1
    end

    it 'schedules a job' do
      expect { subject.save_and_schedule! }.to change { Workers::Deprovisioning::Delete.jobs.count }.from(0).to 1
    end

    it 'sets DeprovisionSchedule#job_id' do
      expect { subject.save_and_schedule! }.to change { subject.job_id }.from(nil).to a_kind_of(String)
    end
  end

  describe '#cancel!' do
    subject { person_email.deprovision_schedules.create action: :delete, scheduled_for: 1.day.from_now, job_id: job_id }

    context 'when job_id is nil' do
      let(:job_id) { nil }

      it 'does not try to cancel the worker' do
        expect(Sidekiq::Status).to_not receive(:cancel)
        subject.cancel!
      end
    end

    context 'when job_id in present' do
      it 'cancels the sidekiq worker' do
        expect(Sidekiq::Status).to receive(:cancel).with(job_id)
        subject.cancel!
      end

      it 'sets canceled to true' do
        expect(Sidekiq::Status).to receive(:cancel)
        expect { subject.cancel! }.to change { !!subject.canceled }.from(false).to true
      end
    end
  end

  describe '#cancel_and_destroy!' do
    subject { person_email.deprovision_schedules.create action: :delete, scheduled_for: 1.day.from_now, job_id: job_id }

    context 'when job_id in nil' do
      let(:job_id) { nil }

      it 'does not cancel the sidekiq job' do
        expect(Sidekiq::Status).to_not receive(:cancel)
        subject.cancel_and_destroy!
      end
    end

    context 'when job_id is present' do
      it 'cancels the sidekiq job' do
        expect(Sidekiq::Status).to receive(:cancel)
        subject.cancel_and_destroy!
      end
    end

    it 'destroys the record' do
      expect(Sidekiq::Status).to receive(:cancel)
      expect { subject.cancel_and_destroy! }.to change { subject.deleted? }.from(false).to true
    end
  end

  context 'when setting completed_at' do
    subject { person_email.deprovision_schedules.create action: :delete, scheduled_for: Time.now }

    it 'updates the state of university_email' do
      expect { subject.update(completed_at: DateTime.now) }.to change(person_email, :state).from(:active).to :deleted
      expect(person_email.changed?).to be false
    end
  end
end
