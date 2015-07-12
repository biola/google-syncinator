require 'spec_helper'

describe DeprovisionSchedule do
  it { is_expected.to be_embedded_in(:university_email) }
  it { is_expected.to have_fields(:action, :reason, :scheduled_for, :completed_at, :canceled, :job_id) }
  it { is_expected.to be_timestamped_document }

  it { is_expected.to validate_presence_of(:action) }
  it { is_expected.to validate_presence_of(:scheduled_for) }
  it { is_expected.to validate_presence_of(:completed_at) }
  it { is_expected.to validate_inclusion_of(:action).to_allow(:notify_of_inactivity, :notify_of_closure, :suspend, :delete, :activate) }
end
