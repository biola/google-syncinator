require 'spec_helper'

describe Client do
  it { is_expected.to have_fields(:name, :slug, :access_id, :secret_key, :active) }

  it { is_expected.to validate_presence_of(:slug) }
  it { is_expected.to validate_presence_of(:access_id) }
  it { is_expected.to validate_presence_of(:secret_key) }

  describe '#to_s' do
    subject { build :client, name: 'The Committee to Elect Bob Dole' }
    it { expect(subject.to_s).to eql 'The Committee to Elect Bob Dole' }
  end
end
