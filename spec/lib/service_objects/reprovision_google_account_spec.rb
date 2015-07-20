require 'spec_helper'

describe ServiceObjects::ReprovisionGoogleAccount do
  let(:fixture) { 'create_user' }
  let(:change_hash) { JSON.parse(File.read("./spec/fixtures/#{fixture}.json")) }
  let(:trogdir_change) { TrogdirChange.new(change_hash) }
  subject { ServiceObjects::ReprovisionGoogleAccount.new(trogdir_change) }

  describe '#call' do
    let!(:university_email) { UniversityEmail.create!(uuid: trogdir_change.person_uuid, address: trogdir_change.university_email, state: :suspended) }

    it 'activates the email' do
      expect { subject.call }.to change { university_email.reload.deprovision_schedules.count }.by 1
    end

    it 'adds an activate deprovision schedule' do
      expect { subject.call }.to change { university_email.reload.state }.from(:suspended).to :active
    end

    it 'creates a Trogdir email' do
      expect { subject.call }.to change(Workers::CreateTrogdirEmail.jobs, :size).by 1
    end

    it 'unexpires the legacy email table' do
      expect { subject.call }.to change(Workers::UnexpireLegacyEmailTable.jobs, :size).by 1 
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
