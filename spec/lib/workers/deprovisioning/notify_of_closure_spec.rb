require 'spec_helper'

describe Workers::Deprovisioning::NotifyOfClosure, type: :unit do
  let(:uuid) { '00000000-0000-0000-0000-000000000000' }
  let(:address) { 'bob.dole@biola.edu' }
  let!(:email) { create :person_email, uuid: uuid, address: address }
  let(:reason) { nil }
  let!(:schedule) { email.deprovision_schedules.create action: :notify_of_closure, scheduled_for: 1.minute.ago, canceled: canceled, reason: reason }

  context 'when deprovision schedule canceled' do
    let(:canceled) { true }

    it 'does not send email' do
      expect_any_instance_of(Emails::NotifyOfClosure).to_not receive(:send!)
      subject.perform(schedule.id)
    end

    it 'does not update completed_at' do
      expect{ subject.perform(schedule.id) }.to_not change { schedule.completed_at }
    end
  end

  context 'when deprovision schedule not canceled' do
    let(:canceled) { false }
    before { email.deprovision_schedules.create action: :suspend, scheduled_for: 7.days.from_now }

    it 'sends an email' do
      expect_any_instance_of(Emails::NotifyOfClosure).to receive(:send!)
      subject.perform(schedule.id)
    end

    it 'marks the schedule complete' do
      expect(TrogdirPerson).to receive(:new).and_return(double(first_or_preferred_name: 'Bob'))
      expect{ subject.perform(schedule.id) }.to change { schedule.reload.completed_at }.from(nil)
    end

    context 'when multiple recipients' do
      let(:bob) { create :person_email }
      let(:liz) { create :person_email }
      let!(:email) { create :department_email, uuids: [bob.uuid, liz.uuid], address: 'dole.for.pres@biola.edu' }

      it 'sends multiple emails' do
        dept_email = instance_double(Emails::NotifyOfClosure)
        expect(Emails::NotifyOfClosure).to receive(:new).with(schedule, email).and_return(dept_email)
        expect(dept_email).to receive(:send!)

        bob_email = instance_double(Emails::NotifyOfClosure)
        expect(Emails::NotifyOfClosure).to receive(:new).with(schedule, bob).and_return(bob_email)
        expect(bob_email).to receive(:send!)

        liz_email = instance_double(Emails::NotifyOfClosure)
        expect(Emails::NotifyOfClosure).to receive(:new).with(schedule, liz).and_return(liz_email)
        expect(liz_email).to receive(:send!)

        subject.perform(schedule.id)
      end
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
