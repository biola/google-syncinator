require 'spec_helper'

describe 'employee leaves then returns', type: :feature  do
  let(:uuid) { '00000000-0000-0000-0000-000000000000' }
  let(:biola_id) { 1234567 }
  let(:address) { 'bob.dole@biola.edu' }
  let(:change_hashes) { ['remove_all_affiliations', 'add_affiliation'].map { |f| JSON.parse(File.read("./spec/fixtures/update_person_#{f}.json")) }}
  subject { Workers::HandleChanges.new }

  before do
    expect(subject).to receive_message_chain(:change_syncs, :start, :perform).and_return double(success?: true, parse: change_hashes)
    expect_any_instance_of(Workers::Trogdir::ChangeFinish).to receive_message_chain(:trogdir, :finish, :perform).and_return double(success?: true)

    # It gets called a second time for the second "page" of results
    expect(Workers::HandleChanges).to receive(:perform_async)

    PersonEmail.create uuid: uuid, address: address, state: :active, created_at: 31.days.ago
    DB[:email].insert(idnumber: biola_id, email: address)
  end

  context 'when recently active' do
    before { allow_any_instance_of(GoogleAccount).to receive(:last_login).and_return 364.days.ago }

    context 'when the account is suspended but not deleted' do
      # We stub these to keep them from running immediately.
      before { expect_any_instance_of(Workers::Deprovisioning::Delete).to receive(:perform) }

      it 'cancels the deletion and reactivates the account' do
        allow(TrogdirPerson).to receive(:new).and_return instance_double(TrogdirPerson, biola_id: biola_id, first_or_preferred_name: 'Bob')
        expect_any_instance_of(Trogdir::APIClient::Emails).to receive(:index).and_return double(perform: double(success?: true, parse: [{'address' => address}]))

        expect_any_instance_of(GoogleAccount).to_not receive(:create!)
        expect_any_instance_of(GoogleAccount).to_not receive(:update!)
        expect_any_instance_of(GoogleAccount).to_not receive(:delete!)
        expect_any_instance_of(GoogleAccount).to_not receive(:join!)
        expect_any_instance_of(GoogleAccount).to_not receive(:leave!)

        expect_any_instance_of(GoogleAccount).to receive(:suspend!)
        expect_any_instance_of(Trogdir::APIClient::Emails).to receive(:destroy).and_return double(perform: double(success?: true))
        expect(Sidekiq::Status).to receive(:cancel).twice
        expect_any_instance_of(GoogleAccount).to receive(:unsuspend!)
        expect_any_instance_of(Trogdir::APIClient::Emails).to receive(:create).and_return double(perform: double(success?: true))

        subject.perform

        expect(PersonEmail.count).to eql 1
        expect(PersonEmail.first.deprovision_schedules.count).to eql 4
        expect(PersonEmail.first.deprovision_schedules.map(&:action)).to eql [:notify_of_closure, :suspend, :delete, :activate]
        expect(PersonEmail.first.deprovision_schedules.map(&:canceled?)).to eql [false, false, true, false]
        expect(PersonEmail.first.deprovision_schedules.map(&:completed_at?)).to eql [true, true, false, true]
        expect(DB[:email].count).to eql 1
        expect(DB[:email].first[:expiration_date]).to be nil
        expect(DB[:email].first[:reusable_date]).to be nil
      end
    end
  end
end
