require 'spec_helper'

describe ServiceObjects::CancelDeprovisioningGoogleAccount, type: :unit do
  let(:fixture) { 'create_employee' }
  let(:change_hash) { JSON.parse(File.read("./spec/fixtures/#{fixture}.json")) }
  let(:trogdir_change) { TrogdirChange.new(change_hash) }
  let!(:university_email) { create :person_email, uuid: trogdir_change.person_uuid, address: trogdir_change.university_email || 'john.doe@example.com' }
  subject { ServiceObjects::CancelDeprovisioningGoogleAccount.new(trogdir_change) }

  describe '#call' do
    let!(:deletion) { university_email.deprovision_schedules.create action: :delete, scheduled_for: 1.day.from_now }

    it 'cancels deprovision schedules' do
      expect { subject.call }.to change { deletion.reload.canceled? }.from(false).to true
    end
  end

  describe '#ignore?' do
    let(:fixture) { 'update_person_add_affiliation' }
    let!(:schedules) { university_email.deprovision_schedules.create action: :delete, scheduled_for: 1.minute.from_now }

    context 'when not changing affiliations' do
      let(:fixture) { 'update_person_name' }
      it { expect(subject.ignore?).to be true }
    end

    context "when universtiy email does not exist" do
      before { university_email.destroy! }
      it { expect(subject.ignore?).to be true }
    end

    context 'when an exclusion exists' do
      before { university_email.exclusions.create creator_uuid: trogdir_change.person_uuid, starts_at: 1.minute.ago, ends_at: 1.minute.from_now }
      it { expect(subject.ignore?).to be true }
    end

    context 'when removing affiliation' do
      let(:fixture) { 'update_person_remove_affiliation' }
      it { expect(subject.ignore?).to be true }
    end

    context 'when adding a non-required affilation' do
      before { allow(Settings).to receive(:affiliations).and_return double(employeeish: [], studentish: [], email_required: [], email_allowed: []) }
      it { expect(subject.ignore?).to be true }
    end

    context 'when adding one affiliations' do
      it { expect(subject.ignore?).to be false }
    end
  end
end
