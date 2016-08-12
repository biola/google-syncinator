require 'spec_helper'

describe Workers::Deprovisioning do
  let(:account_email) { DepartmentEmail.new }
  let(:activity) { :never_active }
  let(:allowed) { nil }
  subject { Workers::Deprovisioning.schedule_for(account_email, activity, allowed)}

  describe '.schedule_for' do
    context 'when a DepartmentEmail' do
      context 'when never active' do
        xit 'returns the right schedule' do
          expect(subject).to include(:suspend)
          expect(subject).to_not include(:notify_of_inactivity, :notify_of_closure, :delete, :activate)
        end
      end

      context 'when inactive' do
        let(:activity) { :inactive }

        xit 'returns the right schedule' do
          expect(subject).to include(:notify_of_inactivity, :suspend)
          expect(subject).to_not include(:notify_of_closure, :delete, :activate)
        end
      end
    end

    context 'when a PersonEmail' do
      let(:account_email) { PersonEmail.new }

      context 'when account is allowed' do
        let(:allowed) { true }

        xit 'returns the right schedule' do
          expect(subject).to include(:suspend, :delete)
          expect(subject).to_not include(:notify_of_inactivity, :notify_of_closure, :activate)
        end
      end

      context 'when account is not allowed' do
        let(:allowed) { false }

        xit 'returns the right schedule' do
          expect(subject).to include(:delete)
          expect(subject).to_not include(:notify_of_inactivity, :notify_of_closure, :suspend, :activate)
        end

        context 'when inactive' do
          let(:activity) { :active }

          xit 'returns the right schedule' do
            expect(subject).to include(:notify_of_closure, :suspend, :delete)
            expect(subject).to_not include(:notify_of_inactivity, :activate)
          end
        end
      end
    end
  end
end
