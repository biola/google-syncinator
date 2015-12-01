require 'spec_helper'

describe DepartmentEmail do
  let(:uuids) { ['00000000-0000-0000-0000-000000000000', '00000000-0000-0000-0000-000000000001'] }
  let(:address) { 'dole.for.pres@biola.edu' }

  it { is_expected.to have_fields(:uuids, :address, :state) }
  it { is_expected.to embed_many :deprovision_schedules }
  it { is_expected.to embed_many :exclusions }
  it { is_expected.to be_timestamped_document }

  it { is_expected.to validate_presence_of(:uuids) }
  it { is_expected.to validate_presence_of(:address) }
  it { is_expected.to validate_presence_of(:state) }
  it { is_expected.to validate_inclusion_of(:state).to_allow(:active, :suspended, :deleted) }

  describe '#notification_recipients' do
    let!(:bob) { PersonEmail.create!(uuid: uuids.first, address: 'bob.dole@biola.edu') }
    let!(:liz) { PersonEmail.create!(uuid: uuids.last, address: 'elizabeth.dole@biola.edu') }

    subject { DepartmentEmail.new uuids: uuids }
    it 'is not implemented' do
      expect(subject.notification_recipients).to eql [subject, bob, liz]
    end
  end

  describe '.sync_to_trogdir?' do
    it 'is false' do
      expect(subject.class.sync_to_trogdir?).to be false
    end
  end

  describe '.sync_to_legacy_email_table?' do
    it 'is false' do
      expect(subject.class.sync_to_legacy_email_table?).to be false
    end
  end

  describe '#to_s' do
    subject { DepartmentEmail.new(uuids: uuids, address: address) }

    it 'returns a string of the uuid and the address' do
      expect(subject.to_s).to eql 'dole.for.pres@biola.edu'
    end
  end

end
