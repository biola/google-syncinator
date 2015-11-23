require 'spec_helper'

describe DepartmentEmail do
  let(:uuids) { ['00000000-0000-0000-0000-000000000000'] }
  let(:address) { 'dole.for.pres@biola.edu' }

  it { is_expected.to have_fields(:uuids, :address, :state) }
  it { is_expected.to embed_many :deprovision_schedules }
  it { is_expected.to embed_many :exclusions }
  it { is_expected.to be_timestamped_document }

  it { is_expected.to validate_presence_of(:uuids) }
  it { is_expected.to validate_presence_of(:address) }
  it { is_expected.to validate_presence_of(:state) }
  it { is_expected.to validate_inclusion_of(:state).to_allow(:active, :suspended, :deleted) }

  describe '#to_s' do
    subject { DepartmentEmail.new(uuids: uuids, address: address) }

    it 'returns a string of the uuid and the address' do
      expect(subject.to_s).to eql 'dole.for.pres@biola.edu'
    end
  end

end
