require 'spec_helper'

describe ServiceObjects::DeprovisionGoogleAccount do
  let(:fixture) { 'create_accepted_student' }
  let(:change_hash) { JSON.parse(File.read("./spec/fixtures/#{fixture}.json")) }
  let(:trogdir_change) { TrogdirChange.new(change_hash) }
  subject { ServiceObjects::DeprovisionGoogleAccount.new(trogdir_change) }

  describe '#call' do
    let(:uuid) { '00000000-0000-0000-0000-000000000000' }
    let!(:university_email) { UniversityEmail.create!(uuid: trogdir_change.person_uuid, address: trogdir_change.university_email) }

    context 'when no affiliations' do
      let(:fixture) { 'update_person_remove_all_affiliations' }

      context 'having never logged in' do
        before { expect(subject).to receive_message_chain(:google_account, :never_logged_in?).and_return true }

        it 'schedules delete' do
          expect(Workers::ScheduleActions).to receive(:perform_async).with(uuid, a_kind_of(Integer), :delete)
          subject.call
        end
      end

      context 'having logged in' do
        before { expect(subject).to receive_message_chain(:google_account, :never_logged_in?).and_return false }

        it 'schedules notify_of_closure, suspend and delete' do
          expect(Workers::ScheduleActions).to receive(:perform_async).with(uuid, a_kind_of(Integer), :notify_of_closure, a_kind_of(Integer), :suspend, a_kind_of(Integer), :delete)
          subject.call
        end
      end
    end

    context 'when just an alumnus' do
      let(:fixture) { 'update_person_remove_affiliation' }

      context 'having never logged in' do
        before { expect(subject).to receive_message_chain(:google_account, :never_logged_in?).and_return true }

        it 'schedules suspend and delete' do
          expect(Workers::ScheduleActions).to receive(:perform_async).with(uuid, a_kind_of(Integer), :suspend, a_kind_of(Integer), :delete)
          subject.call
        end
      end

      context 'having not logged in in over a year' do
        before { allow(subject).to receive(:google_account).and_return double(never_logged_in?: false, inactive?: true) }

        it 'schedules notify_of_inactivity twice, suspend and delete' do
          expect(Workers::ScheduleActions).to receive(:perform_async).with(uuid, a_kind_of(Integer), :notify_of_inactivity, a_kind_of(Integer), :notify_of_inactivity, a_kind_of(Integer), :suspend, a_kind_of(Integer), :delete)
          subject.call
        end
      end

      context 'having logged in in the last year' do
        before { allow(subject).to receive(:google_account).and_return double(never_logged_in?: false, inactive?: false) }

        it 'does nothing' do
          expect(Workers::ScheduleActions).to_not receive(:perform_async)
          subject.call
        end
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
