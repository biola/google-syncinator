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
    let(:fixture) { 'create_user_without_university_email'}

    before do
      expect_any_instance_of(UniqueEmailAddress).to receive(:best).and_return('bob.dole@biola.edu')
      expect(UniversityEmail).to receive :create!
    end

    it 'creates a university email' do
      expect(subject.call).to eql :create
    end

    it 'creates a trogdir email' do
      expect { subject.call }.to change(Workers::CreateTrogdirEmail.jobs, :size).by(1)
    end

    it 'updates the legacy table' do
      expect { subject.call }.to change(Workers::InsertIntoLegacyEmailTable.jobs, :size).by(1)
    end
  end

  describe '#ignore?' do
    context 'when creating a user with a university email' do
      let(:fixture) { 'create_user' }
      before { UniversityEmail.create uuid: trogdir_change.person_uuid, address: trogdir_change.university_email }
      it { expect(subject.ignore?).to be true }
    end

    context 'when creating a user without a university email' do
      let(:fixture) { 'create_user_without_university_email' }
      it { expect(subject.ignore?).to be false }
    end
  end
end
