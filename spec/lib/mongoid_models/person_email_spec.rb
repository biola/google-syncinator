require 'spec_helper'

describe PersonEmail, type: :unit do
  let(:uuid) { '00000000-0000-0000-0000-000000000000' }
  let(:address) { 'bob.dole@biola.edu' }

  it { is_expected.to embed_many(:deprovision_schedules) }
  it { is_expected.to embed_many(:exclusions) }
  it { is_expected.to have_fields(:uuid, :address, :state) }
  it { is_expected.to be_timestamped_document }

  it { is_expected.to validate_presence_of(:uuid) }
  it { is_expected.to validate_presence_of(:address) }
  it { is_expected.to validate_presence_of(:state) }
  it { is_expected.to validate_uniqueness_of(:address).scoped_to(:uuid) }
  it { is_expected.to validate_inclusion_of(:state).to_allow(:active, :suspended, :deleted) }

  describe '#notification_recipients' do
    subject { PersonEmail.new address: address }

    it 'is the address in an array' do
      expect(subject.notification_recipients).to eql [subject]
    end
  end

  describe '.sync_to_trogdir?' do
    it 'is true' do
      expect(subject.class.sync_to_trogdir?).to be true
    end
  end

  describe '.sync_to_legacy_email_table?' do
    it 'is true' do
      expect(subject.class.sync_to_legacy_email_table?).to be true
    end
  end


  describe '#to_s' do
    subject { PersonEmail.new(uuid: uuid, address: address) }

    it 'returns a string of the uuid and the address' do
      expect(subject.to_s).to eql '00000000-0000-0000-0000-000000000000/bob.dole@biola.edu'
    end
  end

  describe '.active?' do
    subject { PersonEmail }

    context 'when no emails' do
      it { expect(subject.active?(uuid)).to be false }
    end

    context 'when an suspended email' do
      before { subject.create uuid: uuid, address: address, state: :suspended }
      it { expect(subject.active?(uuid)).to be false }
    end

    context 'when an active email' do
      before { subject.create uuid: uuid, address: address, state: :active }
      it { expect(subject.active?(uuid)).to be true }
    end
  end

  describe '.find_reprovisionable' do
    let(:uuid) { '00000000-0000-0000-0000-000000000000' }
    context 'when person has no emails' do
      it { expect(PersonEmail.find_reprovisionable(uuid)).to be nil }
    end

    context 'when person has an active email' do
      let!(:email) { PersonEmail.create uuid: uuid, address: address, state: :active }
      it { expect(PersonEmail.find_reprovisionable(uuid)).to be nil }
    end

    context 'when person has a suspended email' do
      let!(:email) { PersonEmail.create uuid: uuid, address: address, state: :suspended }
      it { expect(PersonEmail.find_reprovisionable(uuid)).to eql email }
    end

    context 'when person has a deleted email' do
      let!(:email) { PersonEmail.create uuid: uuid, address: address, state: :deleted }
      it { expect(PersonEmail.find_reprovisionable(uuid)).to eql email }
    end
  end
end
