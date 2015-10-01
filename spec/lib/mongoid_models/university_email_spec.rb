require 'spec_helper'

describe UniversityEmail, type: :unit do
  let(:address) { 'bob.dole@biola.edu' }

  it { is_expected.to have_fields(:address, :state) }
  it { is_expected.to be_timestamped_document }

  it { is_expected.to validate_presence_of(:address) }
  it { is_expected.to validate_presence_of(:state) }
  it { is_expected.to validate_inclusion_of(:state).to_allow(:active, :suspended, :deleted) }

  describe 'validation' do
    context 'when the email address already exists' do
      before { UniversityEmail.create(address: address, state: state)}
      subject { UniversityEmail.new address: address }

      context 'when the email is active' do
        let(:state) { :active }

        it 'is invalid' do
          expect(subject).to be_invalid
        end
      end

      context 'when the email is suspended' do
        let(:state) { :suspended }

        it 'is invalid' do
          expect(subject).to be_invalid
        end
      end

      context 'when the email is deleted' do
        let(:state) { :deleted }

        it 'is valid' do
          expect(subject).to be_valid
        end
      end
    end
  end

  describe '#to_s' do
    subject { UniversityEmail.new(address: address) }

    it 'returns the address as a string' do
      expect(subject.to_s).to eql 'bob.dole@biola.edu'
    end
  end

  describe '.current' do
    context 'without a record' do
      it { expect(UniversityEmail.current(address)).to be nil }
    end

    context 'with a record' do
      before { UniversityEmail.create address: 'bob.dole@biola.edu', state: state }

      context 'when active' do
        let(:state) { :active }
        it { expect(UniversityEmail.current(address)).to be_a UniversityEmail }
      end

      context 'with a suspended record' do
        let(:state) { :suspended }
        it { expect(UniversityEmail.current(address)).to be_a UniversityEmail }
      end

      context 'with deleted record' do
        let(:state) { :deleted }
        it { expect(UniversityEmail.current(address)).to be nil }
      end
    end
  end

  describe '.available?' do
    subject { UniversityEmail }

    context "when email doesn't exist" do
      it { expect(subject.available?(address)).to be true }
    end

    context 'when email is suspended' do
      before { subject.create address: address, state: :suspended }
      it { expect(subject.available?(address)).to be false }
    end

    context 'when email is deleted' do
      before { subject.create address: address, state: :deleted }
      it { expect(subject.available?(address)).to be true }
    end
  end
end
