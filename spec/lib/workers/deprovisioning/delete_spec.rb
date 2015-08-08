require 'spec_helper'

describe Workers::Deprovisioning::Delete, type: :unit do
  describe '#perform' do
    let!(:email) { UniversityEmail.create uuid: '00000000-0000-0000-0000-000000000000', address: 'bob.dole@biola.edu' }
    let!(:schedule) { email.deprovision_schedules.create action: :delete, scheduled_for: 1.minute.ago, canceled: canceled }

    context 'when deprovision schedule canceled' do
      let(:canceled) { true }

      it 'does not delete Google account' do
        expect_any_instance_of(GoogleAccount).to_not receive(:delete!)
        subject.perform(schedule.id)
      end

      it 'does not delete trogdir email' do
        expect(Workers::DeleteTrogdirEmail).to_not receive(:perform_async)
        subject.perform(schedule.id)
      end

      it 'does not expire legacy email' do
        expect(Workers::ExpireLegacyEmailTable).to_not receive(:perform_async)
        subject.perform(schedule.id)
      end

      it 'does not updated completed_at' do
        expect{ subject.perform(schedule.id) }.to_not change { schedule.completed_at }
      end
    end

    context 'when deprovision schedule not canceled' do
      let(:canceled) { false }

      before { expect_any_instance_of(TrogdirPerson).to receive(:biola_id).and_return(1234567) }

      it 'deletes Google account' do
        account = instance_double(GoogleAccount)
        expect(GoogleAccount).to receive(:new).with('bob.dole@biola.edu').and_return(account)
        expect(account).to receive(:delete!)
        subject.perform(schedule.id)
      end

      it 'deletes the trogdir email' do
        expect(GoogleAccount).to receive_message_chain(:new, :delete!)
        expect(Workers::DeleteTrogdirEmail).to receive(:perform_async)
        subject.perform(schedule.id)
      end

      it 'expires the legacy email' do
        expect(GoogleAccount).to receive_message_chain(:new, :delete!)
        expect(Workers::ExpireLegacyEmailTable).to receive(:perform_async)
        subject.perform(schedule.id)
      end

      it 'marks the schedule complete' do
        expect(GoogleAccount).to receive_message_chain(:new, :delete!)
        expect{ subject.perform(schedule.id) }.to change { schedule.reload.completed_at }.from(nil)
      end
    end
  end
end
