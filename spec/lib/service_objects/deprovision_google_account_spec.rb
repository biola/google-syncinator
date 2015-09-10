require 'spec_helper'

describe ServiceObjects::DeprovisionGoogleAccount, type: :unit do
  let(:fixture) { 'update_person_remove_all_affiliations' }
  let(:change_hash) { JSON.parse(File.read("./spec/fixtures/#{fixture}.json")) }
  let(:trogdir_change) { TrogdirChange.new(change_hash) }
  let(:uuid) { '00000000-0000-0000-0000-000000000000' }
  subject { ServiceObjects::DeprovisionGoogleAccount.new(trogdir_change) }

  describe '#call' do
    let!(:university_email) { UniversityEmail.create!(uuid: trogdir_change.person_uuid, address: trogdir_change.university_email, created_at: created_at) }

    context 'when email is protected' do
      let(:created_at) { Time.now - Settings.deprovisioning.protect_for + 86400 }

      it 'schedules deprovisioning for later' do
        expect(Workers::DeprovisionGoogleAccount).to receive(:perform_at).with a_kind_of(Time), a_kind_of(Hash)
        subject.call
      end
    end

    context 'when email is not protected' do
      let(:created_at) { Time.now - Settings.deprovisioning.protect_for - 86400 }

      context 'when no affiliations' do
        context 'having never logged in' do
          before { expect(subject).to receive_message_chain(:google_account, :never_logged_in?).and_return true }

          it 'schedules delete' do
            expect(Workers::ScheduleActions).to receive(:perform_async).with(university_email.id.to_s, [a_kind_of(Integer), :delete], DeprovisionSchedule::LOST_AFFILIATION_REASON)
            subject.call
          end
        end

        context 'having logged in' do
          before { expect(subject).to receive_message_chain(:google_account, :never_logged_in?).and_return false }

          it 'schedules notify_of_closure, suspend and delete' do
            expect(Workers::ScheduleActions).to receive(:perform_async).with(university_email.id.to_s, [a_kind_of(Integer), :notify_of_closure, a_kind_of(Integer), :suspend, a_kind_of(Integer), :delete], DeprovisionSchedule::LOST_AFFILIATION_REASON)
            subject.call
          end
        end
      end

      context 'when just an alumnus' do
        let(:fixture) { 'update_person_remove_affiliation' }

        context 'having never logged in' do
          before { expect(subject).to receive_message_chain(:google_account, :never_logged_in?).and_return true }

          it 'schedules suspend and delete' do
            expect(Workers::ScheduleActions).to receive(:perform_async).with(university_email.id.to_s, [a_kind_of(Integer), :suspend, a_kind_of(Integer), :delete], DeprovisionSchedule::NEVER_ACTIVE_REASON)
            subject.call
          end
        end

        context 'having not logged in in over a year' do
          before { allow(subject).to receive(:google_account).and_return double(never_logged_in?: false, inactive?: true) }

          it 'schedules notify_of_inactivity twice, suspend and delete' do
            expect(Workers::ScheduleActions).to receive(:perform_async).with(university_email.id.to_s, [a_kind_of(Integer), :notify_of_inactivity, a_kind_of(Integer), :notify_of_inactivity, a_kind_of(Integer), :suspend, a_kind_of(Integer), :delete], DeprovisionSchedule::INACTIVE_REASON)
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
  end

  describe '#ignore?' do
    context "when universtiy email doesn't exist" do
      let(:fixture) { 'create_accepted_student' }
      it { expect(subject.ignore?).to be true }
    end

    context 'when not changing affiliations' do
      let(:fixture) { 'update_person_name' }
      it { expect(subject.ignore?).to be true }
    end

    context 'when an exclusion exists' do
      before do
        e = UniversityEmail.create!(uuid: trogdir_change.person_uuid, address: trogdir_change.university_email)
        e.exclusions.create creator_uuid: uuid, starts_at: 1.minute.ago, ends_at: 1.minute.from_now
      end
      it { expect(subject.ignore?).to be true }
    end

    context 'when removing affiliation leaving only allowed affiliaton' do
      let(:fixture) { 'update_person_remove_affiliation' }

      context 'when recently active' do
        before { expect_any_instance_of(GoogleAccount).to receive(:last_login).and_return 364.days.ago }
        it { expect(subject.ignore?).to be true }
      end

      context 'when not recently active' do
        before { expect_any_instance_of(GoogleAccount).to receive(:last_login).and_return 366.days.ago }
        it { expect(subject.ignore?).to be false }
      end

      context 'when never active' do
        before { expect_any_instance_of(GoogleAccount).to receive(:last_login).and_return nil }
        it { expect(subject.ignore?).to be false }
      end
    end

    context 'when removing all affiliations' do
      it { expect(subject.ignore?).to be false }
    end
  end
end
