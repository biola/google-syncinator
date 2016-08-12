require 'spec_helper'

describe 'student graduates', type: :feature  do
  let(:uuid) { '00000000-0000-0000-0000-000000000000' }
  let(:biola_id) { 1234567 }
  let(:address) { 'bob.dole@biola.edu' }
  let(:change_hashes) { ['remove_student', 'add_alumnus'].map { |f| JSON.parse(File.read("./spec/fixtures/update_person_#{f}_affiliation.json")) }}
  subject { Workers::HandleChanges.new }

  before do
    expect(subject).to receive_message_chain(:change_syncs, :start, :perform).and_return double(success?: true, parse: change_hashes)
    expect_any_instance_of(Workers::Trogdir::ChangeFinish).to receive_message_chain(:trogdir, :finish, :perform).and_return double(success?: true)

    # It gets called a second time for the second "page" of results
    expect(Workers::HandleChanges).to receive(:perform_async)

    create :person_email, uuid: uuid, address: address
    DB[:email].insert(idnumber: biola_id, email: address)
  end

  context 'when recently active' do
    before { allow_any_instance_of(GoogleAccount).to receive(:last_login).and_return 364.days.ago }

    # This happens because in this case the user does have no affiliations.
    # If the alumni associaton was added before the student affilation was removed, this shouldn't happen.
    xit 'creates deprovisioning schedules but cancels them' do
      allow(TrogdirPerson).to receive(:new).and_return instance_double(TrogdirPerson, biola_id: biola_id, first_or_preferred_name: 'Bob', last_name: 'Dole', department: nil, title: nil, privacy: false, affiliations: ['alumnus'])
      expect_any_instance_of(GoogleAccount).to receive(:suspended?).and_return false

      expect_any_instance_of(Trogdir::APIClient::Emails).to_not receive(:create)
      expect_any_instance_of(Trogdir::APIClient::Emails).to_not receive(:destroy)
      expect_any_instance_of(GoogleAccount).to_not receive(:create!)
      expect_any_instance_of(GoogleAccount).to_not receive(:suspend!)
      expect_any_instance_of(GoogleAccount).to_not receive(:delete!)
      expect_any_instance_of(GoogleAccount).to_not receive(:join!)
      expect_any_instance_of(GoogleAccount).to_not receive(:leave!)

      expect_any_instance_of(GoogleAccount).to receive(:update!).with first_name: 'Bob', last_name: 'Dole', department: nil, title: nil, privacy: false, org_unit_path: '/Alumni'
      # We stub these to keep them from running immediately. Normally they would
      # run in 5 days which would leave time for the jobs to be canceled.
      expect_any_instance_of(Workers::Deprovisioning::NotifyOfClosure).to receive(:perform)
      expect_any_instance_of(Workers::Deprovisioning::Suspend).to receive(:perform)
      expect_any_instance_of(Workers::Deprovisioning::Delete).to receive(:perform)
      expect(Sidekiq::Status).to receive(:cancel).exactly(3).times

      subject.perform

      expect(PersonEmail.count).to eql 1
      expect(PersonEmail.first.deprovision_schedules.count).to eql 3
      expect(PersonEmail.first.deprovision_schedules.map(&:canceled?)).to eql [true, true, true]
      expect(DB[:email].count).to eql 1
      expect(DB[:email].first[:expiration_date]).to be nil
      expect(DB[:email].first[:reusable_date]).to be nil
    end
  end
end
