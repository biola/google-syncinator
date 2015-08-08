require 'spec_helper'

describe 'create accepted student', type: :feature do
  let(:change_hashes) { [JSON.parse(File.read("./spec/fixtures/create_accepted_student.json"))] }
  subject { Workers::HandleChanges.new }

  before do
    expect(subject).to receive_message_chain(:change_syncs, :start, :perform).and_return double(success?: true, parse: change_hashes)
    expect_any_instance_of(Workers::ChangeFinish).to receive_message_chain(:trogdir, :finish, :perform).and_return double(success?: true)

    # It gets called a second time for the second "page" of results
    expect(Workers::HandleChanges).to receive(:perform_async)
  end

  it 'does nothing' do
    expect_any_instance_of(Trogdir::APIClient::Emails).to_not receive(:create)
    expect_any_instance_of(Trogdir::APIClient::Emails).to_not receive(:destroy)
    expect_any_instance_of(GoogleAccount).to_not receive(:create!)
    expect_any_instance_of(GoogleAccount).to_not receive(:create_or_update!)
    expect_any_instance_of(GoogleAccount).to_not receive(:update_suspension!)
    expect_any_instance_of(GoogleAccount).to_not receive(:delete!)
    expect_any_instance_of(GoogleAccount).to_not receive(:join!)
    expect_any_instance_of(GoogleAccount).to_not receive(:leave!)

    subject.perform

    expect(UniversityEmail.count).to eql 0
    expect(DB[:email].count).to eql 0
  end
end
