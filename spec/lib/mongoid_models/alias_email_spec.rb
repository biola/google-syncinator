require 'spec_helper'

describe AliasEmail, type: :unit do
  let(:address) { 'bob.dole@biola.edu' }

  it { is_expected.to belong_to(:account_email) }
  it { is_expected.to have_fields(:address, :state) }
  it { is_expected.to be_timestamped_document }

  it { is_expected.to validate_presence_of(:address) }
  it { is_expected.to validate_presence_of(:state) }
  it { is_expected.to validate_inclusion_of(:state).to_allow(:active, :suspended, :deleted) }

  describe 'before_create' do
    let(:account_email) { AccountEmail.create! address: 'bobby.dole@biola.edu', state: :suspended }
    let(:alias_email) { AliasEmail.new account_email: account_email, address: address }

    it "uses the account email's state" do
      expect { alias_email.save! }.to change { alias_email.state }.from(:active).to :suspended
    end
  end

  describe '#sync_to_trogdir?' do
    it 'is false' do
      expect(subject.sync_to_trogdir?).to be false
    end
  end

  describe '#sync_to_legacy_email_table?' do
    subject { AliasEmail.new account_email: account_email }

    context 'when account_email is a PersonEmail' do
      let(:account_email) { PersonEmail.new }

      it 'is true' do
        expect(subject.sync_to_legacy_email_table?).to be true
      end
    end

    context 'when account_email is a DepartmentEmail' do
      let(:account_email) { DepartmentEmail.new }

      it 'is false' do
        expect(subject.sync_to_legacy_email_table?).to be false
      end
    end
  end

end
