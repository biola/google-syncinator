require 'spec_helper'

describe UniversityEmail, type: :model do
  it { is_expected.to have_fields(:uuid, :address, :primary, :state) }
  it { is_expected.to be_timestamped_document }

  it { is_expected.to validate_presence_of(:uuid) }
  it { is_expected.to validate_presence_of(:address) }
  it { is_expected.to validate_presence_of(:primary) }
  it { is_expected.to validate_presence_of(:state) }
  it { is_expected.to validate_uniqueness_of(:address).scoped_to(:uuid) }
  it { is_expected.to validate_inclusion_of(:state).to_allow(:active, :suspended, :deleted) }
end
