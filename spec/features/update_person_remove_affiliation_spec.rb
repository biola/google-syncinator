require 'spec_helper'

describe 'remove affilation leaving alumnus only', type: :feature  do
  let(:uuid) { '00000000-0000-0000-0000-000000000000' }
  let(:biola_id) { 1234567 }
  let(:address) { 'bob.dole@biola.edu' }
  let(:change_hashes) { [JSON.parse(File.read("./spec/fixtures/update_person_remove_affiliation.json"))] }
  subject { Workers::HandleChanges.new }

  before do
    expect(subject).to receive_message_chain(:change_syncs, :start, :perform).and_return double(success?: true, parse: change_hashes)
    expect_any_instance_of(Workers::Trogdir::ChangeFinish).to receive_message_chain(:trogdir, :finish, :perform).and_return double(success?: true)

    # It gets called a second time for the second "page" of results
    expect(Workers::HandleChanges).to receive(:perform_async)

    PersonEmail.create uuid: uuid, address: address, state: :active, created_at: 31.days.ago
    DB[:email].insert(idnumber: biola_id, email: address)
  end

  context 'when never active' do
    it 'schedules a suspension and deletion' do
      allow(TrogdirPerson).to receive(:new).and_return instance_double(TrogdirPerson, biola_id: biola_id, first_or_preferred_name: 'Bob', last_name: 'Dole', department: nil, title: nil, privacy: false, affiliations: [])
      allow_any_instance_of(GoogleAccount).to receive(:last_login).and_return nil
      allow_any_instance_of(GoogleAccount).to receive(:suspended?).and_return false

      expect_any_instance_of(Trogdir::APIClient::Emails).to_not receive(:create)
      expect_any_instance_of(GoogleAccount).to_not receive(:create!)
      expect_any_instance_of(GoogleAccount).to_not receive(:join!)
      expect_any_instance_of(GoogleAccount).to_not receive(:leave!)

      expect_any_instance_of(GoogleAccount).to receive(:update!).with 'Bob', 'Dole', nil, nil, false, '/'
      expect_any_instance_of(GoogleAccount).to receive(:suspend!)
      api_double = double
      expect(api_double).to receive(:index).twice.and_return double(perform: double(success?: true, parse: [{'id' => '42', 'address' => address}]))
      expect(api_double).to receive(:destroy).twice.and_return double(perform: double(success?: true))
      expect(Trogdir::APIClient::Emails).to receive(:new).exactly(4).times.and_return api_double
      expect_any_instance_of(GoogleAccount).to receive(:delete!)

      subject.perform

      expect(PersonEmail.count).to eql 1
      expect(PersonEmail.first.deprovision_schedules.count).to eql 2
      suspension = PersonEmail.first.deprovision_schedules.find_by(action: :suspend)
      expect(suspension.action).to eql :suspend
      expect(suspension.completed_at?).to be true
      deletion = PersonEmail.first.deprovision_schedules.find_by(action: :delete)
      expect(deletion.action).to eql :delete
      expect(deletion.completed_at?).to be true
      expect(DB[:email].count).to eql 1
      expect(DB[:email].first[:expiration_date]).to_not be nil
      expect(DB[:email].first[:reusable_date]).to_not be nil
    end
  end

  context 'when a long time since active' do
    it 'schedules two notices of inactivity, a suspension and a deletion' do
      allow(TrogdirPerson).to receive(:new).and_return instance_double(TrogdirPerson, biola_id: biola_id, first_or_preferred_name: 'Bob', last_name: 'Dole', department: nil, title: nil, privacy: false, affiliations: [])
      allow_any_instance_of(GoogleAccount).to receive(:last_login).and_return 366.days.ago
      allow_any_instance_of(GoogleAccount).to receive(:suspended?).and_return false

      expect_any_instance_of(Trogdir::APIClient::Emails).to_not receive(:create)
      expect_any_instance_of(GoogleAccount).to_not receive(:create!)
      expect_any_instance_of(GoogleAccount).to_not receive(:join!)
      expect_any_instance_of(GoogleAccount).to_not receive(:leave!)

      expect_any_instance_of(GoogleAccount).to receive(:update!).with 'Bob', 'Dole', nil, nil, false, '/'
      expect_any_instance_of(GoogleAccount).to receive(:suspend!)
      api_double = double
      expect(api_double).to receive(:index).twice.and_return double(perform: double(success?: true, parse: [{'id' => '42', 'address' => address}]))
      expect(api_double).to receive(:destroy).twice.and_return double(perform: double(success?: true))
      expect(Trogdir::APIClient::Emails).to receive(:new).exactly(4).times.and_return api_double
      expect_any_instance_of(GoogleAccount).to receive(:delete!)

      subject.perform

      expect(PersonEmail.count).to eql 1
      expect(PersonEmail.first.deprovision_schedules.count).to eql 4
      suspension = PersonEmail.first.deprovision_schedules.find_by(action: :suspend)
      expect(suspension.action).to eql :suspend
      expect(suspension.completed_at?).to be true
      deletion = PersonEmail.first.deprovision_schedules.find_by(action: :delete)
      expect(deletion.action).to eql :delete
      expect(deletion.completed_at?).to be true
      expect(DB[:email].count).to eql 1
      expect(DB[:email].first[:expiration_date]).to_not be nil
      expect(DB[:email].first[:reusable_date]).to_not be nil
    end
  end

  context 'when recently active' do
    it 'does nothing' do
      allow(TrogdirPerson).to receive(:new).and_return instance_double(TrogdirPerson, biola_id: biola_id, first_or_preferred_name: 'Bob', last_name: 'Dole', department: nil, title: nil, privacy: false, affiliations: [])
      allow_any_instance_of(GoogleAccount).to receive(:last_login).and_return 364.days.ago
      allow_any_instance_of(GoogleAccount).to receive(:suspended?).and_return false

      expect_any_instance_of(Trogdir::APIClient::Emails).to_not receive(:create)
      expect_any_instance_of(Trogdir::APIClient::Emails).to_not receive(:destroy)
      expect_any_instance_of(GoogleAccount).to_not receive(:create!)
      expect_any_instance_of(GoogleAccount).to_not receive(:suspend!)
      expect_any_instance_of(GoogleAccount).to_not receive(:delete!)
      expect_any_instance_of(GoogleAccount).to_not receive(:join!)
      expect_any_instance_of(GoogleAccount).to_not receive(:leave!)

      expect_any_instance_of(GoogleAccount).to receive(:update!).with 'Bob', 'Dole', nil, nil, false, '/'

      subject.perform

      expect(PersonEmail.count).to eql 1
      expect(PersonEmail.first.deprovision_schedules.count).to eql 0
      expect(DB[:email].count).to eql 1
      expect(DB[:email].first[:expiration_date]).to be nil
      expect(DB[:email].first[:reusable_date]).to be nil
    end
  end
end
