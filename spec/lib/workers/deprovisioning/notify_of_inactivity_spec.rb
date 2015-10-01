require 'spec_helper'

describe Workers::Deprovisioning::NotifyOfInactivity, type: :unit do
  let!(:email) { PersonEmail.create uuid: '00000000-0000-0000-0000-000000000000', address: 'bob.dole@biola.edu' }
  let(:reason) { nil }
  let!(:schedule) { email.deprovision_schedules.create action: :notify_of_inactivity, scheduled_for: 1.minute.ago, canceled: canceled, reason: reason }

  context 'when deprovision schedule canceled' do
    let(:canceled) { true }

    it 'does not cancel deprovisioning' do
      expect_any_instance_of(AccountEmail).to_not receive :cancel_deprovisioning!
      subject.perform(schedule.id)
    end

    it 'does not send email' do
      expect_any_instance_of(Emails::NotifyOfInactivity).to_not receive(:send!)
      subject.perform(schedule.id)
    end

    it 'does not updated completed_at' do
      expect{ subject.perform(schedule.id) }.to_not change { schedule.completed_at }
    end
  end

  context 'when deprovision schedule not canceled' do
    let(:canceled) { false }
    before { email.deprovision_schedules.create action: :suspend, scheduled_for: 7.days.from_now }

    context 'when user logged in within the last year' do
      before do
        expect_any_instance_of(GoogleAccount).to receive(:last_login).and_return 364.days.ago
        allow(Sidekiq::Status).to receive(:cancel)
      end

      it 'cancels deprovisioning' do
        expect_any_instance_of(AccountEmail).to receive :cancel_deprovisioning!
        subject.perform(schedule.id)
      end

      it 'does not send email' do
        expect_any_instance_of(Emails::NotifyOfInactivity).to_not receive(:send!)
        subject.perform(schedule.id)
      end

      it 'does not mark the schedule complete' do
        expect{ subject.perform(schedule.id) }.to_not change { schedule.completed_at }
      end
    end

    context 'when user has not logged in within the last year' do
      before { allow_any_instance_of(GoogleAccount).to receive(:last_login).and_return 366.days.ago }

      it 'does not cancel deprovisioning' do
        expect_any_instance_of(AccountEmail).to_not receive :cancel_deprovisioning!
        expect(TrogdirPerson).to receive(:new).and_return(double(first_or_preferred_name: 'Bob'))
        subject.perform(schedule.id)
      end

      it 'sends an email' do
        expect_any_instance_of(Emails::NotifyOfInactivity).to receive(:send!)
        subject.perform(schedule.id)
      end

      it 'marks the schedule complete' do
        expect(TrogdirPerson).to receive(:new).and_return(double(first_or_preferred_name: 'Bob'))
        expect{ subject.perform(schedule.id) }.to change { schedule.reload.completed_at }.from(nil)
      end

      context "when email was inactive but now isn't" do
        let(:reason) { DeprovisionSchedule::INACTIVE_REASON }
        before { expect_any_instance_of(GoogleAccount).to receive(:active?).and_return true }

        it 'cancels the schedule' do
          expect { subject.perform(schedule.id) }.to change { schedule.reload.canceled? }.to true
        end
      end
    end
  end
end
