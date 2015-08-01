require 'spec_helper'

describe GoogleAccount, type: :unit do
  let(:email) { 'bob.dole' }
  subject { GoogleAccount.new(email) }

  describe '#active?' do
    context 'when less than a year since last login' do
      it 'is true' do
        expect(subject).to receive(:last_login).and_return 364.days.ago
        expect(subject.active?).to be true
      end
    end

    context 'when more than a year since last login' do
      it 'is false' do
        expect(subject).to receive(:last_login).and_return 366.days.ago
        expect(subject.active?).to be false
      end
    end
  end

  describe '#inactive?' do
    context 'when less than a year since last login' do
      it 'is false' do
        expect(subject).to receive(:last_login).and_return 364.days.ago
        expect(subject.inactive?).to be false
      end
    end

    context 'when more than a year since last login' do
      it 'is true' do
        expect(subject).to receive(:last_login).and_return 366.days.ago
        expect(subject.inactive?).to be true
      end
    end
  end

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
