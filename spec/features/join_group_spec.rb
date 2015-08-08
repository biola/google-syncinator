require 'spec_helper'

describe 'join a group', type: :feature do
  let(:biola_id) { 1234567 }
  let(:uuid) { '00000000-0000-0000-0000-000000000000' }
  let(:address) { 'bob.dole@biola.edu' }
  let(:change_hashes) { [JSON.parse(File.read("./spec/fixtures/join_group.json"))] }
  subject { Workers::HandleChanges.new }

  before do
    expect(subject).to receive_message_chain(:change_syncs, :start, :perform).and_return double(success?: true, parse: change_hashes)
    expect_any_instance_of(Workers::ChangeFinish).to receive_message_chain(:trogdir, :finish, :perform).and_return double(success?: true)

    # It gets called a second time for the second "page" of results
    expect(Workers::HandleChanges).to receive(:perform_async)

    UniversityEmail.create uuid: uuid, address: address, state: :suspended
    DB[:email].insert idnumber: biola_id, email: address, expiration_date: 1.month.ago, reusable_date: 1.week.ago
  end

  it 'calls GoogleAccount#join!' do
    allow(Settings).to receive_message_chain(:groups, :whitelist).and_return ['Politician', 'President']

    expect_any_instance_of(Trogdir::APIClient::Emails).to_not receive(:create)
    expect_any_instance_of(Trogdir::APIClient::Emails).to_not receive(:destroy)
    expect_any_instance_of(GoogleAccount).to_not receive(:create!)
    expect_any_instance_of(GoogleAccount).to_not receive(:create_or_update!)
    expect_any_instance_of(GoogleAccount).to_not receive(:update_suspension!)
    expect_any_instance_of(GoogleAccount).to_not receive(:delete!)
    expect_any_instance_of(GoogleAccount).to_not receive(:leave!)

    account = instance_double(GoogleAccount)
    expect(account).to receive(:join!).with 'President'
    expect(GoogleAccount).to receive(:new).with(address).and_return account

    subject.perform

    expect(UniversityEmail.count).to eql 1
    expect(DB[:email].count).to eql 1
  end
end
