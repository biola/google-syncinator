require 'spec_helper'

describe 'create accepted student', type: :feature do
  let(:change_hashes) { [JSON.parse(File.read("./spec/fixtures/create_email.json"))] }
  subject { Workers::HandleChanges.new }

  before do
    expect(subject).to receive_message_chain(:change_syncs, :start, :perform).and_return double(success?: true, parse: change_hashes)
    expect_any_instance_of(Workers::Trogdir::ChangeFinish).to receive_message_chain(:trogdir, :finish, :perform).and_return double(success?: true)

    # It gets called a second time for the second "page" of results
    expect(Workers::HandleChanges).to receive(:perform_async)
  end

  it 'creates a google account' do
    expect(TrogdirPerson).to receive(:new).and_return instance_double(TrogdirPerson, first_or_preferred_name: 'Bob', last_name: 'Dole', department: nil, title: nil, privacy: false)
    expect_any_instance_of(GoogleAccount).to receive(:suspended?).and_return false

    expect_any_instance_of(Trogdir::APIClient::Emails).to_not receive(:create)
    expect_any_instance_of(Trogdir::APIClient::Emails).to_not receive(:destroy)
    expect_any_instance_of(GoogleAccount).to_not receive(:update_suspension!)
    expect_any_instance_of(GoogleAccount).to_not receive(:rename!)
    expect_any_instance_of(GoogleAccount).to_not receive(:delete!)
    expect_any_instance_of(GoogleAccount).to_not receive(:join!)
    expect_any_instance_of(GoogleAccount).to_not receive(:leave!)

    expect_any_instance_of(GoogleAccount).to receive(:create_or_update!)

    subject.perform

    expect(UniversityEmail.count).to eql 0
    expect(DB[:email].count).to eql 0
  end
end
