require 'spec_helper'

describe Workers::Deprovisioning::Suspend, type: :unit do
  let(:uuid) { '00000000-0000-0000-0000-000000000000' }
  let(:address) { 'bob.dole@biola.edu' }
  let!(:email) { create :person_email, uuid: uuid, address: address }
  let(:reason) { nil }
  let!(:schedule) { email.deprovision_schedules.create action: :suspend, scheduled_for: 1.minute.ago, canceled: canceled, reason: reason }

  context 'when deprovision schedule canceled' do
    let(:canceled) { true }

    it 'does not suspend Google account' do
      expect_any_instance_of(GoogleAccount).to_not receive(:suspend!)
      subject.perform(schedule.id)
    end

    it 'does not delete trogdir email' do
      expect(Workers::Trogdir::DeleteEmail).to_not receive(:perform_async)
      subject.perform(schedule.id)
    end

    it 'does not expire legacy email' do
      expect(Workers::LegacyEmailTable::Expire).to_not receive(:perform_async)
      subject.perform(schedule.id)
    end

    it 'does not updated completed_at' do
      expect{ subject.perform(schedule.id) }.to_not change { schedule.completed_at }
    end
  end

  context 'when deprovision schedule not canceled' do
    let(:canceled) { false }

    before do
      allow_any_instance_of(TrogdirPerson).to receive(:biola_id).and_return(1234567)
      allow_any_instance_of(GoogleAccount).to receive(:suspend!)
    end

    context 'when a PersonEmail' do
      it 'suspends Google account' do
        account = instance_double(GoogleAccount)
        expect(GoogleAccount).to receive(:new).with('bob.dole@biola.edu').and_return(account)
        expect(account).to receive(:suspend!)
        subject.perform(schedule.id)
      end

      it 'deletes the trogdir email' do
        expect(Workers::Trogdir::DeleteEmail).to receive(:perform_async)
        subject.perform(schedule.id)
      end

      it 'expires the legacy email' do
        expect(Workers::LegacyEmailTable::Expire).to receive(:perform_async)
        subject.perform(schedule.id)
      end

      it 'marks the schedule complete' do
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

    context 'when a DepartmentEmail' do
      let!(:email) { create :department_email, uuids: [uuid], address: address }

      it 'suspends Google account' do
        account = instance_double(GoogleAccount)
        expect(GoogleAccount).to receive(:new).with('bob.dole@biola.edu').and_return(account)
        expect(account).to receive(:suspend!)
        subject.perform(schedule.id)
      end

      it 'does not delete a trogdir email' do
        expect(Workers::Trogdir::DeleteEmail).to_not receive(:perform_async)
        subject.perform(schedule.id)
      end

      it 'does not expire a legacy email' do
        expect(Workers::LegacyEmailTable::Expire).to_not receive(:perform_async)
        subject.perform(schedule.id)
      end

      it 'marks the schedule complete' do
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
