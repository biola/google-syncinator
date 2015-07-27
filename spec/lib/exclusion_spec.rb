require 'spec_helper'

describe Exclusion do
  it { is_expected.to be_embedded_in(:university_email) }
  it { is_expected.to have_fields(:creator_uuid, :starts_at, :ends_at, :reason) }
  it { is_expected.to be_timestamped_document }

  it { is_expected.to validate_presence_of(:creator_uuid) }
  it { is_expected.to validate_presence_of(:starts_at) }

  describe '#validate' do
    let(:starts_at) { Time.now }
    subject { Exclusion.new(creator_uuid: '00000000-0000-0000-0000-000000000000', starts_at: starts_at, ends_at: ends_at) }
    context 'when ends_at is nil' do
      let(:ends_at) { nil }
      it { expect(subject).to be_valid }
    end

    context 'when ends_at is after starts_at' do
      let(:ends_at) { starts_at + 1 }
      it { expect(subject).to be_valid }
    end

    context 'when ends_at is before starts_at' do
      let(:ends_at) { starts_at - 1 }
      it { expect(subject).to be_invalid }
    end
  end
end
