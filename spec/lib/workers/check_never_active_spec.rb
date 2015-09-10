require 'spec_helper'

describe Workers::CheckNeverActive, type: :unit do
  context 'without inactive emails' do
    before { expect(GoogleAccount).to receive(:never_active).and_return [] }

    it 'does nothing' do
      expect { Workers::CheckNeverActive.new.perform }.to_not change { Workers::ScheduleActions.jobs.length }.from 0
    end
  end

  context 'with never active emails' do
    let(:uuid) { '00000000-0000-0000-0000-000000000000' }
    let(:address) { 'bob.dole@biola.edu' }
    let(:created_at) { 31.days.ago }
    let!(:email) { UniversityEmail.create(uuid: uuid, address: address, created_at: created_at) }

    before { expect(GoogleAccount).to receive(:never_active).and_return [address] }

    context 'when email is not being deprovisioned' do
      context 'when email is protected' do
        let(:created_at) { 29.days.ago }

        it 'does not schedule deprovisioning' do
          expect { Workers::CheckNeverActive.new.perform }.to_not change { Workers::ScheduleActions.jobs.length }.from 0
        end
      end

      context 'when email is not protected' do
        before { expect_any_instance_of(TrogdirPerson).to receive(:affiliations).and_return affiliations}

        context 'when person is an employee' do
          let(:affiliations) { ['employee'] }

          it 'does not schedule deprovisioning' do
            expect { Workers::CheckNeverActive.new.perform }.to_not change { Workers::ScheduleActions.jobs.length }.from 0
          end
        end

        context 'when person is just an alumnus' do
          context "when they're really inactive" do
            let(:affiliations) { ['alumnus'] }
            before { expect_any_instance_of(GoogleAccount).to receive(:never_active?).and_return true }

            it 'scheduled deprovisioning' do
              expect(Workers::ScheduleActions).to receive(:perform_async).with(email.id.to_s, [a_kind_of(Integer), :suspend, a_kind_of(Integer), :delete], DeprovisionSchedule::NEVER_ACTIVE_REASON)
              Workers::CheckNeverActive.new.perform
            end
          end

          context 'when they really have been active recently' do
            let(:affiliations) { ['alumnus'] }
            before { expect_any_instance_of(GoogleAccount).to receive(:never_active?).and_return false }

            it 'does nothing' do
              expect(Workers::ScheduleActions).to_not receive(:perform_async)
              Workers::CheckNeverActive.new.perform
            end
          end
        end
      end
    end

    context 'when email is being deprovisioned' do
      before { email.deprovision_schedules.create action: :delete, scheduled_for: 1.week.from_now }

      it 'does not schedule deprovisioning' do
        expect { Workers::CheckNeverActive.new.perform }.to_not change { Workers::ScheduleActions.jobs.length }.from 0
      end
    end
  end
end
