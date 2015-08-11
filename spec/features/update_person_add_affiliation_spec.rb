require 'spec_helper'

describe 'add an employee affiliation', type: :feature  do
  let(:uuid) { '00000000-0000-0000-0000-000000000000' }
  let(:biola_id) { 1234567 }
  let(:address) { 'bob.dole@biola.edu' }
  let(:change_hashes) { [JSON.parse(File.read("./spec/fixtures/update_person_add_affiliation.json"))] }
  subject { Workers::HandleChanges.new }

  before do
    expect(subject).to receive_message_chain(:change_syncs, :start, :perform).and_return double(success?: true, parse: change_hashes)
    expect_any_instance_of(Workers::ChangeFinish).to receive_message_chain(:trogdir, :finish, :perform).and_return double(success?: true)

    # It gets called a second time for the second "page" of results
    expect(Workers::HandleChanges).to receive(:perform_async)
  end

  context 'when a reprovisionable email exists' do
    before do
      UniversityEmail.create uuid: uuid, address: address, state: :suspended
      DB[:email].insert(idnumber: biola_id, email: address, expiration_date: 1.month.ago, reusable_date: 1.week.ago)
    end

    it 'creates a Trogdir email and activates the university email and legacy email' do
      expect(TrogdirPerson).to receive(:new).and_return instance_double(TrogdirPerson, biola_id: biola_id)

      expect_any_instance_of(Trogdir::APIClient::Emails).to_not receive(:destroy)
      expect_any_instance_of(GoogleAccount).to_not receive(:create_or_update!)
      expect_any_instance_of(GoogleAccount).to_not receive(:update_suspension!)
      expect_any_instance_of(GoogleAccount).to_not receive(:delete!)
      expect_any_instance_of(GoogleAccount).to_not receive(:join!)
      expect_any_instance_of(GoogleAccount).to_not receive(:leave!)

      expect_any_instance_of(Trogdir::APIClient::Emails).to receive(:create).and_return double(perform: double(success?: true))

      subject.perform

      expect(UniversityEmail.count).to eql 1
      expect(UniversityEmail.first.address).to eql address
      expect(UniversityEmail.first.state).to eql :active
      expect(UniversityEmail.first.deprovision_schedules.count).to eql 1
      expect(UniversityEmail.first.deprovision_schedules.last.action).to eql :activate
      expect(UniversityEmail.first.deprovision_schedules.last.completed_at?).to be true
      expect(DB[:email].count).to eql 1
      expect(DB[:email].first[:primary]).to eql 1
      expect(DB[:email].first[:expiration_date]).to be nil
      expect(DB[:email].first[:reusable_date]).to be nil
    end
  end

  context 'when no reprovisionable email exists' do
    it 'creates a trogdir, university and legacy email' do
      allow_any_instance_of(UniversityEmail).to receive(:available?).and_return(true)
      allow_any_instance_of(GoogleAccount).to receive(:available?).and_return(true)

      expect_any_instance_of(Trogdir::APIClient::Emails).to_not receive(:destroy)
      expect_any_instance_of(GoogleAccount).to_not receive(:create_or_update!)
      expect_any_instance_of(GoogleAccount).to_not receive(:update_suspension!)
      expect_any_instance_of(GoogleAccount).to_not receive(:delete!)
      expect_any_instance_of(GoogleAccount).to_not receive(:join!)
      expect_any_instance_of(GoogleAccount).to_not receive(:leave!)

      expect_any_instance_of(Trogdir::APIClient::Emails).to receive(:create).and_return(double(perform: double(success?: true)))

      subject.perform

      expect(UniversityEmail.count).to eql 1
      expect(DB[:email].count).to eql 1
    end
  end
end
