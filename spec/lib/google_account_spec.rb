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
end
