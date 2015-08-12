require 'spec_helper'

describe 'update an email address', type: :feature  do
  let(:uuid) { '00000000-0000-0000-0000-000000000000' }
  let(:biola_id) { 1234567 }
  let(:old_address) { 'bobby.dole@biola.edu' }
  let(:new_address) { 'bob.dole@biola.edu' }
  let(:change_hashes) { [JSON.parse(File.read("./spec/fixtures/update_email.json"))] }
  subject { Workers::HandleChanges.new }

  before do
    expect(subject).to receive_message_chain(:change_syncs, :start, :perform).and_return double(success?: true, parse: change_hashes)
    expect_any_instance_of(Workers::ChangeFinish).to receive_message_chain(:trogdir, :finish, :perform).and_return double(success?: true)

    # It gets called a second time for the second "page" of results
    expect(Workers::HandleChanges).to receive(:perform_async)

    UniversityEmail.create uuid: uuid, address: old_address
    DB[:email].insert(idnumber: 1234567, email: old_address, primary: 1)
  end

  it 'marks the old email not primary and creates a new primary email' do
    expect(TrogdirPerson).to receive(:new).and_return instance_double(TrogdirPerson, biola_id: biola_id)

    expect_any_instance_of(Trogdir::APIClient::Emails).to_not receive(:create)
    expect_any_instance_of(Trogdir::APIClient::Emails).to_not receive(:destroy)
    expect_any_instance_of(GoogleAccount).to_not receive(:create_or_update!)
    expect_any_instance_of(GoogleAccount).to_not receive(:update_suspension!)
    expect_any_instance_of(GoogleAccount).to_not receive(:delete!)
    expect_any_instance_of(GoogleAccount).to_not receive(:join!)
    expect_any_instance_of(GoogleAccount).to_not receive(:leave!)

    account = instance_double(GoogleAccount)
    expect(account).to receive(:rename!).with(new_address)
    expect(GoogleAccount).to receive(:new).with(old_address).and_return account

    expect(DB[:email].count).to eql 1
    expect(DB[:email].first[:email]).to eql old_address

    subject.perform

    expect(UniversityEmail.count).to eql 2
    expect(UniversityEmail.find_by(uuid: uuid, address: old_address).primary).to be false
    expect(UniversityEmail.where(uuid: uuid, address: new_address, primary: true).any?).to be true
    expect(DB[:email].count).to eql 2
    expect(DB[:email].where(email: old_address).first[:primary]).to eql 0
    new_email_record = DB[:email].where(email: new_address).first
    expect(new_email_record[:primary]).to eql 1
  end
end
