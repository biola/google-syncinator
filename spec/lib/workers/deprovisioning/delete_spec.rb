require 'spec_helper'

describe Workers::Deprovisioning::Delete, type: :unit do
  describe '#perform' do
    let(:uuid) { '00000000-0000-0000-0000-000000000000' }
    let(:address) { 'bob.dole@biola.edu' }
    let!(:email) { create :person_email, uuid: uuid, address: address }
    let(:reason) { nil }
    let!(:schedule) { email.deprovision_schedules.create action: :delete, scheduled_for: 1.minute.ago, canceled: canceled, reason: reason }

    context 'when deprovision schedule canceled' do
      let(:canceled) { true }

      it 'does not delete Google account' do
        expect_any_instance_of(GoogleAccount).to_not receive(:delete!)
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

      before { allow_any_instance_of(GoogleAccount).to receive(:delete!) }

      context 'when a PersonEmail' do
        before { allow_any_instance_of(TrogdirPerson).to receive(:biola_id).and_return(1234567) }

        it 'deletes Google account' do
          account = instance_double(GoogleAccount)
          expect(GoogleAccount).to receive(:new).with('bob.dole@biola.edu').and_return(account)
          expect(account).to receive(:delete!)
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
          before { expect_any_instance_of(GoogleAccount).to_not receive(:delete!) }

          it 'cancels the schedule' do
            expect { subject.perform(schedule.id) }.to change { schedule.reload.canceled? }.to true
          end
        end
      end

      context 'when a DepartmenEmail' do
        let!(:email) { create :department_email, uuids: [uuid], address: address }

        it 'deletes Google account' do
          account = instance_double(GoogleAccount)
          expect(GoogleAccount).to receive(:new).with('bob.dole@biola.edu').and_return(account)
          expect(account).to receive(:delete!)
          subject.perform(schedule.id)
        end

        it 'does not delete the trogdir email' do
          expect(Workers::Trogdir::DeleteEmail).to_not receive(:perform_async)
          subject.perform(schedule.id)
        end

        it 'does not expire the legacy email' do
          expect(Workers::LegacyEmailTable::Expire).to_not receive(:perform_async)
          subject.perform(schedule.id)
        end

        it 'marks the schedule complete' do
          expect{ subject.perform(schedule.id) }.to change { schedule.reload.completed_at }.from(nil)
        end

        context "when email was inactive but now isn't" do
          let(:reason) { DeprovisionSchedule::INACTIVE_REASON }
          before { expect_any_instance_of(GoogleAccount).to receive(:active?).and_return true }
          before { expect_any_instance_of(GoogleAccount).to_not receive(:delete!) }

          it 'cancels the schedule' do
            expect { subject.perform(schedule.id) }.to change { schedule.reload.canceled? }.to true
          end
        end
      end

      context 'when an AliasEmail' do
        let(:person_email) { create :person_email, address: 'bobby.dole@biola.edu', uuid: uuid }
        let!(:email) { create :alias_email, account_email: person_email, address: address }

        before do
          allow_any_instance_of(GoogleAccount).to receive(:delete_alias!)
          allow_any_instance_of(TrogdirPerson).to receive(:biola_id).and_return(1234567)
        end

        it 'deletes Google alias account' do
          account = instance_double(GoogleAccount)
          expect(GoogleAccount).to receive(:new).with('bobby.dole@biola.edu').and_return(account)
          expect(account).to receive(:delete_alias!).with(address)
          subject.perform(schedule.id)
        end

        it 'does not delete the trogdir email' do
          expect(Workers::Trogdir::DeleteEmail).to_not receive(:perform_async)
          subject.perform(schedule.id)
        end

        it 'expires the legacy email' do
          expect(Workers::LegacyEmailTable::Expire).to receive(:perform_async)
          subject.perform(schedule.id)
        end

        it 'marks the schedule complete' do
          expect{ subject.perform(schedule.id) }.to change { schedule.reload.completed_at }.from(nil)
        end
      end
    end
  end
end
