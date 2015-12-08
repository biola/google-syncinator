require 'spec_helper'

describe ServiceObjects::AssignEmailAddress, type: :unit do
  let(:fixture) { 'create_accepted_student' }
  let(:change_hash) { JSON.parse(File.read("./spec/fixtures/#{fixture}.json")) }
  let(:trogdir_change) { TrogdirChange.new(change_hash) }
  subject { ServiceObjects::AssignEmailAddress.new(trogdir_change) }

  context 'when creating a accepted student' do
    it 'does nothing' do
      expect(subject.call).to be nil
    end
  end

  context 'when creating an employee' do
    let(:address) { 'bob.dole@biola.edu' }
    let(:fixture) { 'create_employee_without_university_email'}

    before do
      expect_any_instance_of(UniqueEmailAddress).to receive(:best).and_return(address)
      expect(Workers::CreatePersonEmail).to receive(:perform_async).with(change_hash['person_id'], address)
    end

    it 'creates a university email' do
      expect(subject.call).to eql :create
    end
  end

  describe '#ignore?' do
    context "when the user's UUID is in Settings.prevent_creation" do
      let(:fixture) { 'create_employee_without_university_email'}

      it 'is true' do
        expect(Settings).to receive(:prevent_creation).and_return [change_hash['person_id']]
        expect(subject.ignore?).to be true
      end
    end

    context 'when creating a user with a university email' do
      let(:fixture) { 'create_employee' }
      before { PersonEmail.create uuid: trogdir_change.person_uuid, address: trogdir_change.university_email }
      it { expect(subject.ignore?).to be true }
    end

    context 'when creating a user without a university email' do
      let(:fixture) { 'create_employee_without_university_email' }
      it { expect(subject.ignore?).to be false }
    end
  end
end
