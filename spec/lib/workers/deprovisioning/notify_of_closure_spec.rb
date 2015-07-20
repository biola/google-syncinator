require 'spec_helper'

describe Workers::Deprovisioning::NotifyOfClosure do
  let!(:email) { UniversityEmail.create uuid: '00000000-0000-0000-0000-000000000000', address: 'bob.dole@biola.edu' }

  context 'when deprovision schedule canceled' do
    let!(:schedule) { email.deprovision_schedules.create action: :notify_of_closure, scheduled_for: 1.minute.ago, canceled: true }

    it 'does not send email' do
      expect_any_instance_of(Emails::NotifyOfClosure).to_not receive(:send!)
      subject.perform(email.id)
    end

    it 'does not updated completed_at' do
      expect{ subject.perform(email.id) }.to_not change { schedule.completed_at }
    end
  end

  context 'when deprovision schedule not canceled' do
    let!(:schedule) { email.deprovision_schedules.create action: :notify_of_closure, scheduled_for: 1.minute.ago }
    before { email.deprovision_schedules.create action: :suspend, scheduled_for: 7.days.from_now }

    it 'sends an email' do
      expect_any_instance_of(Emails::NotifyOfClosure).to receive(:send!)
      subject.perform(email.id)
    end

    it 'marks the schedule complete' do
      expect(TrogdirPerson).to receive(:new).and_return(double(first_or_preferred_name: 'Bob'))
      expect{ subject.perform(email.id) }.to change { schedule.reload.completed_at }.from(nil)
    end
  end
end
