require 'spec_helper'

describe Workers::Deprovisioning::Activate, type: :unit do
  let(:uuid) { '00000000-0000-0000-0000-000000000000' }
  let(:address) { 'bob.dole@biola.edu' }
  let(:email) { PersonEmail.create uuid: uuid, address: address, state: state }
  let(:schedule) { email.deprovision_schedules.create action: :activate, scheduled_for: 1.minute.ago }

  describe '#perform' do
    context 'when email is already active' do
      let(:state) { :active }

      it 'does nothing' do
        subject.perform(schedule.id)
        expect(email.state).to eql :active
        expect_any_instance_of(GoogleAccount).to_not receive :unsuspend!
        expect(Workers::Trogdir::CreateEmail.jobs).to be_empty
        expect(Workers::LegacyEmailTable::Unexpire.jobs).to be_empty
      end
    end

    context 'when email is suspended' do
      let(:state) { :suspended }
      before { expect_any_instance_of(GoogleAccount).to receive :unsuspend! }

      context 'when a PersonEmail' do
        before { expect_any_instance_of(TrogdirPerson).to receive(:biola_id).and_return 1234567 }

        it 'activates the email' do
          expect { subject.perform(schedule.id) }.to change { email.reload.state }.from(:suspended).to :active
        end

        it 'adds an activate deprovision schedule' do
          expect { subject.perform(schedule.id) }.to change { email.reload.deprovision_schedules.count }.by 1
        end

        it 'creates a Trogdir email' do
          expect { subject.perform(schedule.id) }.to change(Workers::Trogdir::CreateEmail.jobs, :size).by 1
        end

        it 'unexpires the legacy email table' do
          expect { subject.perform(schedule.id) }.to change(Workers::LegacyEmailTable::Unexpire.jobs, :size).by 1
        end
      end

      context 'when a DepartmentEmail' do
        let(:email) { DepartmentEmail.create uuids: [uuid], address: address, state: state }

        it 'activates the email' do
          expect { subject.perform(schedule.id) }.to change { email.reload.state }.from(:suspended).to :active
        end

        it 'adds an activate deprovision schedule' do
          expect { subject.perform(schedule.id) }.to change { email.reload.deprovision_schedules.count }.by 1
        end

        it 'does not create a Trogdir email' do
          expect { subject.perform(schedule.id) }.to_not change(Workers::Trogdir::CreateEmail.jobs, :size)
        end

        it 'does not unexpire the legacy email table' do
          expect { subject.perform(schedule.id) }.to_not change(Workers::LegacyEmailTable::Unexpire.jobs, :size)
        end
      end
    end
  end
end
