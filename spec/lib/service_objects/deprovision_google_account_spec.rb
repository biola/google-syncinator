require 'spec_helper'

describe ServiceObjects::DeprovisionGoogleAccount do
  let(:fixture) { 'create_accepted_student' }
  let(:change_hash) { JSON.parse(File.read("./spec/fixtures/#{fixture}.json")) }
  let(:trogdir_change) { TrogdirChange.new(change_hash) }
  subject { ServiceObjects::DeprovisionGoogleAccount.new(trogdir_change) }

  describe '#call' do
    let!(:university_email) { UniversityEmail.create!(uuid: trogdir_change.person_uuid, address: trogdir_change.university_email) }

    context 'when no affiliations' do
      let(:fixture) { 'update_person_remove_all_affiliations' }

      context 'having never logged in' do
        before { expect(subject).to receive_message_chain(:google_account, :never_logged_in?).and_return true }
        it { expect { subject.call }.to change { university_email.reload.deprovision_schedules.where(action: :delete).count }.from(0).to 1 }
      end

      context 'having logged in' do
        before { expect(subject).to receive_message_chain(:google_account, :never_logged_in?).and_return false }
        it { expect { subject.call }.to change { university_email.reload.deprovision_schedules.where(action: :notify_of_closure).count }.from(0).to 1 }
        it { expect { subject.call }.to change { university_email.reload.deprovision_schedules.where(action: :suspend).count }.from(0).to 1 }
        it { expect { subject.call }.to change { university_email.reload.deprovision_schedules.where(action: :delete).count }.from(0).to 1 }
      end
    end

    context 'when just an alumnus' do
      let(:fixture) { 'update_person_remove_affiliation' }

      context 'having never logged in' do
        before { expect(subject).to receive_message_chain(:google_account, :never_logged_in?).and_return true }
        it { expect { subject.call }.to change { university_email.reload.deprovision_schedules.where(action: :suspend).count }.from(0).to 1 }
        it { expect { subject.call }.to change { university_email.reload.deprovision_schedules.where(action: :delete).count }.from(0).to 1 }
      end

      context 'having not logged in in over a year' do
        before { allow(subject).to receive(:google_account).and_return double(never_logged_in?: false, last_login: 13.months.ago) }
        it { expect { subject.call }.to change { university_email.reload.deprovision_schedules.where(action: :notify_of_inactivity).count }.from(0).to 2 }
        it { expect { subject.call }.to change { university_email.reload.deprovision_schedules.where(action: :suspend).count }.from(0).to 1 }
        it { expect { subject.call }.to change { university_email.reload.deprovision_schedules.where(action: :delete).count }.from(0).to 1 }
      end

      context 'having logged in the last year' do
        before { expect(subject).to receive_message_chain(:google_account, :never_logged_in?).and_return false }

      end
    end
  end

  describe '#ignore?' do
    context "when universtiy email doesn't exist" do
      it { expect(subject.ignore?).to be true }
    end

    context 'when not changing affiliations' do
      let(:fixture) { 'update_person_name' }
      it { expect(subject.ignore?).to be true }
    end

    context 'when removing one affiliation' do
      let(:fixture) { 'update_person_remove_affiliation' }
      it { expect(subject.ignore?).to be true }
    end

    context 'when removing all affiliations' do
      let(:fixture) { 'update_person_remove_all_affiliations' }
      it { expect(subject.ignore?).to be false }
    end
  end
end
