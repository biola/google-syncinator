require 'spec_helper'

describe 'update person name', type: :feature  do
  let(:uuid) { '00000000-0000-0000-0000-000000000000' }
  let(:biola_id) { 1234567 }
  let(:address) { 'bob.dole@biola.edu' }
  let(:change_hashes) { [JSON.parse(File.read("./spec/fixtures/update_person_name.json"))] }
  subject { Workers::HandleChanges.new }

  before do
    expect(subject).to receive_message_chain(:change_syncs, :start, :perform).and_return double(success?: true, parse: change_hashes)
    expect_any_instance_of(Workers::Trogdir::ChangeFinish).to receive_message_chain(:trogdir, :finish, :perform).and_return double(success?: true)

    # It gets called a second time for the second "page" of results
    expect(Workers::HandleChanges).to receive(:perform_async)

    PersonEmail.create uuid: uuid, address: address, state: :active
    DB[:email].insert(idnumber: biola_id, email: address)
  end

  it 'syncs the google account data' do
    expect(TrogdirPerson).to receive(:new).and_return instance_double(TrogdirPerson, first_or_preferred_name: 'B-dizzle', last_name: 'Dole', department: 'Office of the President', title: 'Commander in Chief', privacy: false, affiliations: ['employee'])
    expect_any_instance_of(GoogleAccount).to receive(:suspended?).and_return false

    expect_any_instance_of(Trogdir::APIClient::Emails).to_not receive(:create)
    expect_any_instance_of(Trogdir::APIClient::Emails).to_not receive(:destroy)
    expect_any_instance_of(GoogleAccount).to_not receive(:update_suspension!)
    expect_any_instance_of(GoogleAccount).to_not receive(:delete!)
    expect_any_instance_of(GoogleAccount).to_not receive(:join!)
    expect_any_instance_of(GoogleAccount).to_not receive(:leave!)

    expect_any_instance_of(GoogleAccount).to receive(:update!).with('B-dizzle', 'Dole', 'Office of the President', 'Commander in Chief', false, '/Employees')

    subject.perform

    expect(PersonEmail.count).to eql 1
    expect(DB[:email].count).to eql 1
  end
end
