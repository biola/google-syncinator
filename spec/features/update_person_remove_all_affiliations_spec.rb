require 'spec_helper'

describe 'remove all affiliations', type: :feature  do
  let(:uuid) { '00000000-0000-0000-0000-000000000000' }
  let(:biola_id) { 1234567 }
  let(:address) { 'bob.dole@biola.edu' }
  let(:change_hashes) { [JSON.parse(File.read("./spec/fixtures/update_person_remove_all_affiliations.json"))] }
  subject { Workers::HandleChanges.new }

  before do
    expect(subject).to receive_message_chain(:change_syncs, :start, :perform).and_return double(success?: true, parse: change_hashes)
    expect_any_instance_of(Workers::Trogdir::ChangeFinish).to receive_message_chain(:trogdir, :finish, :perform).and_return double(success?: true)

    # It gets called a second time for the second "page" of results
    expect(Workers::HandleChanges).to receive(:perform_async)

    create :person_email, uuid: uuid, address: address
    DB[:email].insert(idnumber: biola_id, email: address)
  end

  context 'when never active' do
    it 'schedules a deletion' do
      allow(TrogdirPerson).to receive(:new).and_return instance_double(TrogdirPerson, biola_id: biola_id, first_or_preferred_name: 'Bob', last_name: 'Dole', department: nil, title: nil, privacy: false, affiliations: [])
      allow_any_instance_of(GoogleAccount).to receive(:last_login).and_return nil
      allow_any_instance_of(GoogleAccount).to receive(:suspended?).and_return false

      expect_any_instance_of(Trogdir::APIClient::Emails).to_not receive(:create)
      expect_any_instance_of(GoogleAccount).to_not receive(:create!)
      expect_any_instance_of(GoogleAccount).to_not receive(:suspend!)
      expect_any_instance_of(GoogleAccount).to_not receive(:join!)
      expect_any_instance_of(GoogleAccount).to_not receive(:leave!)

      expect_any_instance_of(GoogleAccount).to receive(:update!)
      api_double = double
      expect(api_double).to receive(:index).and_return double(perform: double(success?: true, parse: [{'id' => '42', 'address' => address}]))
      expect(api_double).to receive(:destroy).and_return double(perform: double(success?: true))
      expect(Trogdir::APIClient::Emails).to receive(:new).twice.times.and_return api_double
      expect_any_instance_of(GoogleAccount).to receive(:delete!)

      subject.perform

      expect(PersonEmail.count).to eql 1
      expect(PersonEmail.first.deprovision_schedules.count).to eql 1
      deletion = PersonEmail.first.deprovision_schedules.find_by(action: :delete)
      expect(deletion.action).to eql :delete
      expect(deletion.completed_at?).to be true
      expect(DB[:email].count).to eql 1
      expect(DB[:email].first[:expiration_date]).to_not be nil
      expect(DB[:email].first[:reusable_date]).to_not be nil
    end
  end

  context 'when has been active' do
    it 'schedules a notice of closure, suspension and deletion' do
      allow(TrogdirPerson).to receive(:new).and_return instance_double(TrogdirPerson, biola_id: biola_id, first_or_preferred_name: 'Bob', last_name: 'Dole', department: nil, title: nil, privacy: false, affiliations: [])
      allow_any_instance_of(GoogleAccount).to receive(:last_login).and_return 366.days.ago
      allow_any_instance_of(GoogleAccount).to receive(:suspended?).and_return false

      expect_any_instance_of(Trogdir::APIClient::Emails).to_not receive(:create)
      expect_any_instance_of(GoogleAccount).to_not receive(:create!)
      expect_any_instance_of(GoogleAccount).to_not receive(:join!)
      expect_any_instance_of(GoogleAccount).to_not receive(:leave!)

      expect_any_instance_of(GoogleAccount).to receive(:update!)
      expect_any_instance_of(GoogleAccount).to receive(:suspend!)
      api_double = double
      expect(api_double).to receive(:index).twice.and_return double(perform: double(success?: true, parse: [{'id' => '42', 'address' => address}]))
      expect(api_double).to receive(:destroy).twice.and_return double(perform: double(success?: true))
      expect(Trogdir::APIClient::Emails).to receive(:new).exactly(4).times.and_return api_double
      expect_any_instance_of(GoogleAccount).to receive(:delete!)

      subject.perform

      expect(PersonEmail.count).to eql 1
      expect(PersonEmail.first.deprovision_schedules.count).to eql 3
      notification = PersonEmail.first.deprovision_schedules.find_by(action: :notify_of_closure)
      expect(notification.action).to eql :notify_of_closure
      expect(notification.completed_at?).to be true
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
end
