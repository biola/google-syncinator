require 'spec_helper'

describe GoogleAccount do
  let(:email) { 'bob.dole' }
  subject { GoogleAccount.new(email) }

  describe '#full_email' do
    it { expect(subject.full_email).to eql 'bob.dole@example.com' }
  end

  describe '.full_email' do
    it { expect(GoogleAccount.full_email('john.kerry')).to eql 'john.kerry@example.com' }
  end

  describe '.group_to_email' do
    it { expect(GoogleAccount.group_to_email('Stewart 1st Back Suites')).to eql 'stewart.1st.back.suites@example.com' }
    it { expect(GoogleAccount.group_to_email('Some Dorm #1  North')).to eql 'some.dorm.1.north@example.com' }
  end
end
