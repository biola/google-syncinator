require 'spec_helper'

describe ServiceObjects::ReprovisionGoogleAccount do
  let(:fixture) { 'create_user' }
  let(:change_hash) { JSON.parse(File.read("./spec/fixtures/#{fixture}.json")) }
  let(:trogdir_change) { TrogdirChange.new(change_hash) }
  subject { ServiceObjects::ReprovisionGoogleAccount.new(trogdir_change) }

  describe '#call' do
    let!(:university_email) { UniversityEmail.create!(uuid: trogdir_change.person_uuid, address: trogdir_change.university_email, state: :suspended) }

    it 'calls Workers::Deprovisioning::Activate' do
      expect(Workers::Deprovisioning::Activate).to receive(:perform_async).with(university_email.id)
      subject.call
    end
  end

  describe '#ignore?' do
    context "when universtiy email does exist" do
      before { UniversityEmail.create! uuid: trogdir_change.person_uuid, address: trogdir_change.university_email }
      it { expect(subject.ignore?).to be true }
    end

    context 'when not changing affiliations' do
      let(:fixture) { 'update_person_name' }
      it { expect(subject.ignore?).to be true }
    end

    context 'when remove affiliation' do
      let(:fixture) { 'update_person_remove_affiliation' }
      before { UniversityEmail.create! uuid: trogdir_change.person_uuid, address: trogdir_change.university_email }
      it { expect(subject.ignore?).to be true }
    end

    context 'when adding one affiliations' do
      let(:fixture) { 'update_person_add_affiliation' }
      before { UniversityEmail.create! uuid: trogdir_change.person_uuid, address: 'test@example.com', state: :suspended }
      it { expect(subject.ignore?).to be false }
    end
  end
end
