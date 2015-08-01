require 'spec_helper'

describe Workers::CheckInactive, type: :unit do
  context 'without inactive emails' do
    before { expect(GoogleAccount).to receive(:inactive).and_return [] }

    it 'does nothing' do
      expect { Workers::CheckInactive.new.perform }.to_not change { Workers::ScheduleActions.jobs.length }.from 0
    end
  end

  context 'with inactive emails' do
    let(:uuid) { '00000000-0000-0000-0000-000000000000' }
    let(:address) { 'bob.dole@biola.edu' }
    let(:created_at) { 31.days.ago }
    let!(:email) { UniversityEmail.create(uuid: uuid, address: address, created_at: created_at) }

    before { expect(GoogleAccount).to receive(:inactive).and_return [address] }

    context 'when email is not being deprovisioned' do
      context 'when email is protected' do
        let(:created_at) { 29.days.ago }

        it 'does not schedule deprovisioning' do
          expect { Workers::CheckInactive.new.perform }.to_not change { Workers::ScheduleActions.jobs.length }.from 0
        end
      end

      context 'when email is not protected' do
        before { expect_any_instance_of(TrogdirPerson).to receive(:affiliations).and_return affiliations}

        context 'when the person is an employee' do
          let(:affiliations) { ['employee'] }

          it 'does not schedule deprovisioning' do
            expect { Workers::CheckInactive.new.perform }.to_not change { Workers::ScheduleActions.jobs.length }.from 0
          end
        end

        context 'when the person is just an alumnus' do
          context "when they're really inactive" do
            let(:affiliations) { ['alumnus'] }
            before { expect_any_instance_of(GoogleAccount).to receive(:inactive?).and_return true }

            it 'scheduled deprovisioning' do
              expect(Workers::ScheduleActions).to receive(:perform_async).with(uuid, a_kind_of(Integer), :notify_of_inactivity, a_kind_of(Integer), :notify_of_inactivity, a_kind_of(Integer), :suspend, a_kind_of(Integer), :delete)
              Workers::CheckInactive.new.perform
            end
          end

          context 'when they really have been active recently' do
            let(:affiliations) { ['alumnus'] }
            before { expect_any_instance_of(GoogleAccount).to receive(:inactive?).and_return false }

            it 'does nothing' do
              expect(Workers::ScheduleActions).to_not receive(:perform_async)
              Workers::CheckInactive.new.perform
            end
          end
        end
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
