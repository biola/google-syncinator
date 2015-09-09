require 'spec_helper'

describe Workers::ScheduleActions, type: :unit do
  let(:uuid) { '00000000-0000-0000-0000-000000000000' }
  let(:address) { 'bob.dole@biola.edu' }
  let(:actions_and_durations) { [1.day.to_i, :notify_of_inactivity, 2.days.to_i, :notify_of_closure, 1.week.to_i, :suspend, 2.weeks.to_i, :delete] }

  describe '#perform' do
    let!(:email) { UniversityEmail.create!(uuid: uuid, address: address, state: state) }

    context 'with active emails' do
      context 'when scheduling an activation' do
        let(:state) { :suspended }
        let(:actions_and_durations) { [1.year.to_i, :activate] }

        it 'creates an activate deprovision schedule' do
          Workers::ScheduleActions.new.perform(email.id.to_s, *actions_and_durations)
          expect(email.reload.deprovision_schedules.length).to eql 1
        end
      end

      context 'when scheduling a deprovisioning' do
        let(:state) { :active }

        it 'creates notify, suspend and delete deprovision schedules' do
          Workers::ScheduleActions.new.perform(email.id.to_s, *actions_and_durations)
          expect(email.reload.deprovision_schedules.length).to eql 4
        end

        context 'when deprovision schedules arleady exist' do
          before { Workers::ScheduleActions.new.perform(email.id.to_s, *actions_and_durations) }

          it 'cancels them' do
            expect(Sidekiq::Status).to receive(:cancel).exactly(4).times
            Workers::ScheduleActions.new.perform(email.id.to_s, 1.day.to_i, :delete)
            expect(email.reload.deprovision_schedules.where(canceled: true).length).to eql 4
            expect(email.reload.deprovision_schedules.where(:canceled.ne => true).length).to eql 1
          end
        end
      end
    end

    context 'without active emails' do
      let(:state) { :deleted }

      it 'does nothing' do
        expect { Workers::ScheduleActions.new.perform(email.id.to_s, *actions_and_durations) }.to_not change { email.deprovision_schedules.length }.from(0)
      end
    end
  end
end
