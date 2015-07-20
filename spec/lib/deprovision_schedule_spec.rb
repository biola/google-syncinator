require 'spec_helper'

describe DeprovisionSchedule do
  it { is_expected.to be_embedded_in(:university_email) }
  it { is_expected.to have_fields(:action, :reason, :scheduled_for, :completed_at, :canceled, :job_id) }
  it { is_expected.to be_timestamped_document }

  it { is_expected.to validate_presence_of(:action) }
  it { is_expected.to validate_presence_of(:scheduled_for) }
  it { is_expected.to validate_presence_of(:completed_at) }
  it { is_expected.to validate_inclusion_of(:action).to_allow(:notify_of_inactivity, :notify_of_closure, :suspend, :delete, :activate) }

  context 'when setting completed_at' do
    let(:uuid) { '00000000-0000-0000-0000-000000000000' }
    let(:address) { 'bob.dole@biola.edu' }

    let(:university_email) { UniversityEmail.create uuid: uuid, address: address }
    subject { university_email.deprovision_schedules.create action: :delete, scheduled_for: Time.now }

    it 'updates the state of university_email' do
      expect { subject.update(completed_at: DateTime.now) }.to change(university_email, :state).from(:active).to :deleted
      expect(university_email.changed?).to be false
    end
  end
end
