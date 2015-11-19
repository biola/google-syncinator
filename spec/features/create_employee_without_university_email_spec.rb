require 'spec_helper'

describe 'create employee', type: :feature do
  let(:uuid) { '00000000-0000-0000-0000-000000000000' }
  let(:address) { 'bob.dole@biola.edu' }
  let(:biola_id) { 1234567 }
  let(:change_hashes) { [JSON.parse(File.read("./spec/fixtures/create_employee_without_university_email.json"))] }
  subject { Workers::HandleChanges.new }

  before do
    expect(subject).to receive_message_chain(:change_syncs, :start, :perform).and_return double(success?: true, parse: change_hashes)
    expect_any_instance_of(Workers::Trogdir::ChangeFinish).to receive_message_chain(:trogdir, :finish, :perform).and_return double(success?: true)

    # It gets called a second time for the second "page" of results
    expect(Workers::HandleChanges).to receive(:perform_async)
  end

  context 'when reprovisionable email exists' do
    before do
      PersonEmail.create uuid: uuid, address: address, state: :suspended
      DB[:email].insert idnumber: biola_id, email: address, expiration_date: 1.month.ago, reusable_date: 1.week.ago
    end

    it 'creates a Trogdir email, unsuspends the Google account and activates the university email and legacy email' do
      expect(TrogdirPerson).to receive(:new).with(uuid).and_return double(biola_id: biola_id)

      expect_any_instance_of(Trogdir::APIClient::Emails).to_not receive(:destroy)
      expect_any_instance_of(GoogleAccount).to_not receive(:create!)
      expect_any_instance_of(GoogleAccount).to_not receive(:update!)
      expect_any_instance_of(GoogleAccount).to_not receive(:delete!)
      expect_any_instance_of(GoogleAccount).to_not receive(:join!)
      expect_any_instance_of(GoogleAccount).to_not receive(:leave!)

      expect_any_instance_of(GoogleAccount).to receive(:unsuspend!)
      expect_any_instance_of(Trogdir::APIClient::Emails).to receive(:create).and_return(double(perform: double(success?: true)))

      subject.perform

      expect(PersonEmail.count).to eql 1
      expect(PersonEmail.first.state).to eql :active
      expect(PersonEmail.first.deprovision_schedules.last.action).to eql :activate

      expect(DB[:email].count).to eql 1
      expect(DB[:email].first[:expiration_date]).to be nil
      expect(DB[:email].first[:reusable_date]).to be nil
    end
  end

  context 'when reprovisionable email does not exist' do
    it 'creates a trogdir, person, legacy and Google email' do
      expect(TrogdirPerson).to receive(:new).with(uuid).and_return double(biola_id: biola_id, first_or_preferred_name: 'Bob', last_name: 'Dole', title: nil, department: nil, privacy: false, affiliations: ['student'])
      allow_any_instance_of(UniversityEmail).to receive(:available?).and_return(true)
      allow_any_instance_of(GoogleAccount).to receive(:available?).and_return(true)

      expect_any_instance_of(Trogdir::APIClient::Emails).to_not receive(:destroy)
      expect_any_instance_of(GoogleAccount).to_not receive(:update!)
      expect_any_instance_of(GoogleAccount).to_not receive(:update_suspension!)
      expect_any_instance_of(GoogleAccount).to_not receive(:delete!)
      expect_any_instance_of(GoogleAccount).to_not receive(:join!)
      expect_any_instance_of(GoogleAccount).to_not receive(:leave!)

      expect_any_instance_of(GoogleAccount).to receive(:create!)
      expect_any_instance_of(Trogdir::APIClient::Emails).to receive(:create).and_return(double(perform: double(success?: true)))

      subject.perform

      expect(PersonEmail.count).to eql 1
      expect(DB[:email].count).to eql 1
    end
  end
end
