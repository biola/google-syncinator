require 'spec_helper'

describe Workers::CreateAliasEmail, type: :unit do
  let(:account_email) { create :department_email }
  let(:account_email_id) { account_email.id.to_s }
  let(:address) { 'bobby.dole@biola.edu' }
  let(:biola_id) { 1234567 }
  subject { Workers::CreateAliasEmail.new }

  before { expect_any_instance_of(GoogleAccount).to receive(:create_alias!).with(address) }

  it 'creates an alias email' do
    expect { subject.perform(account_email_id, address) }.to change { AliasEmail.count }.from(0).to 1
    expect(AliasEmail.first.attributes).to include 'account_email_id' => BSON::ObjectId.from_string(account_email_id), 'address' => address, 'state' => :active
  end

  it 'does not create a trogdir email' do
    expect { subject.perform(account_email_id, address) }.to_not change(Workers::Trogdir::CreateEmail.jobs, :size)
  end

  context 'when account_email is not a PersonEmail' do
    it 'does not update the legacy table' do
      expect { subject.perform(account_email_id, address) }.to_not change(Workers::LegacyEmailTable::Insert.jobs, :size)
    end
  end

  context 'when account_email is a PersonEmail' do
    let(:uuid) { '00000000-0000-0000-0000-000000000000' }
    let(:account_email) { create :person_email, uuid: uuid }
    before { expect(TrogdirPerson).to receive(:new).with(uuid).and_return double(biola_id: biola_id) }

    it 'updates the legacy table' do
      expect { subject.perform(account_email_id, address) }.to change(Workers::LegacyEmailTable::Insert.jobs, :size).by(1)
    end
  end
end
