require 'spec_helper'

describe GoogleAccount, type: :unit do
  let(:email) { 'bob.dole' }
  before { allow(Settings.google).to receive(:domain).and_return 'example.com' }
  subject { GoogleAccount.new(email) }

  describe 'properties' do
    before do
      expect(subject).to receive(:data).at_least(1).times.and_return(
        'name' => {'givenName' => 'Bob', 'familyName' => 'Dole'},
        'organizations' => ['department' => 'Office of the Pres', 'title' => 'Pres'],
        'includeInGlobalAddressList' => true,
        'orgUnitPath' => '/BabyKissers'
      )
    end

    describe '#first_name' do
      it 'returns the givenName from Google' do
        expect(subject.first_name).to eql 'Bob'
      end
    end

    describe '#last_name' do
      it 'returns the familyName from Google' do
        expect(subject.last_name).to eql 'Dole'
      end
    end

    describe '#department' do
      it 'returns the organization department from Google' do
        expect(subject.department).to eql 'Office of the Pres'
      end
    end

    describe '#title' do
      it 'returns the title from Google' do
        expect(subject.title).to eql 'Pres'
      end
    end

    describe '#privacy' do
      it 'returns the includeInGlobalAddressList setting from Google' do
        expect(subject.privacy).to eql false
      end
    end

    describe '#org_unit_path' do
      it 'returns the orgUnitPath from Google' do
        expect(subject.org_unit_path).to eql '/BabyKissers'
      end
    end

    describe '#to_hash' do
      it 'return a hash of the properties' do
        expect(subject.to_hash).to eql(
          address: 'bob.dole@example.com',
          first_name: 'Bob',
          last_name: 'Dole',
          department: 'Office of the Pres',
          title: 'Pres',
          privacy: false,
          org_unit_path: '/BabyKissers'
        )
      end
    end
  end

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

  describe '.full_email' do
    it { expect(GoogleAccount.full_email('john.kerry')).to eql 'john.kerry@example.com' }
  end

  describe '.group_to_email' do
    it { expect(GoogleAccount.group_to_email('Stewart 1st Back Suites')).to eql 'stewart.1st.back.suites@example.com' }
    it { expect(GoogleAccount.group_to_email('Some Dorm #1  North')).to eql 'some.dorm.1.north@example.com' }
  end
end
