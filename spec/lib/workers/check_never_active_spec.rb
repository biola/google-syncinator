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
    let!(:email) { create :person_email, uuid: uuid, address: address, created_at: created_at }

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
          let(:affiliations) { ['alumnus'] }
          # before { expect_any_instance_of(GoogleAccount).to receive(:never_active?).and_return true }

          xit 'scheduled deprovisioning' do
            expect(Workers::ScheduleActions).to receive(:perform_async).with(email.id.to_s, [a_kind_of(Integer), :suspend, a_kind_of(Integer), :delete], DeprovisionSchedule::NEVER_ACTIVE_REASON)
            Workers::CheckNeverActive.new.perform
          end
        end
      end
    end

    context 'when email is being deprovisioned' do
      before { allow_any_instance_of(TrogdirPerson).to receive(:affiliations).and_return ['alumnus'] }

      it 'does not schedule deprovisioning' do
        email.deprovision_schedules.create action: :delete, scheduled_for: 1.week.from_now, reason: DeprovisionSchedule::NEVER_ACTIVE_REASON
        expect { Workers::CheckNeverActive.new.perform }.to_not change { Workers::ScheduleActions.jobs.length }.from 0
      end

      context 'when email has become active' do
        let(:other_email) { create :person_email }
        let!(:schedule) { other_email.deprovision_schedules.create action: :delete, scheduled_for: 1.week.from_now, reason: DeprovisionSchedule::NEVER_ACTIVE_REASON }

        it 'cancels the deprovisioning' do
          expect { Workers::CheckNeverActive.new.perform }.to change { schedule.reload.canceled? }
        end
      end
    end

    context 'when email is excluded' do
      before { email.exclusions.create! creator_uuid: uuid, starts_at: 1.minute.ago }

      it 'does not schedule deprovisioning' do
        expect { Workers::CheckNeverActive.new.perform }.to_not change { Workers::ScheduleActions.jobs.length }.from 0
      end
    end
  end
end
