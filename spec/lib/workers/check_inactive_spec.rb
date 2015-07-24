require 'spec_helper'

describe Workers::CheckInactive do
  context 'without inactive emails' do
    before { expect(GoogleAccount).to receive(:inactive).and_return [] }

    it 'does nothing' do
      expect { Workers::CheckInactive.new.perform }.to_not change { Workers::ScheduleActions.jobs.length }.from 0
    end
  end

  context 'with inactive emails' do
    let(:uuid) { '00000000-0000-0000-0000-000000000000' }
    let(:address) { 'bob.dole@biola.edu' }
    let!(:email) { UniversityEmail.create(uuid: uuid, address: address) }

    before { expect(GoogleAccount).to receive(:inactive).and_return [address] }

    context 'when email is not being deprovisioned' do
      it 'scheduled deprovisioning' do
        expect(Workers::ScheduleActions).to receive(:perform_async).with(uuid, a_kind_of(Integer), :notify_of_inactivity, a_kind_of(Integer), :notify_of_inactivity, a_kind_of(Integer), :suspend, a_kind_of(Integer), :delete)
        Workers::CheckInactive.new.perform
      end
    end

    context 'when email is being deprovisioned' do
      before { email.deprovision_schedules.create action: :delete, scheduled_for: 1.week.from_now }

      it 'does not schedule deprovisioning' do
        expect { Workers::CheckInactive.new.perform }.to_not change { Workers::ScheduleActions.jobs.length }.from 0
      end
    end
  end
end
