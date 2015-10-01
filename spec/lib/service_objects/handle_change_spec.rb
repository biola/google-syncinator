require 'spec_helper'

describe ServiceObjects::HandleChange, type: :unit do
  let(:fixture) { 'create_employee' }
  let(:change_hash) { JSON.parse(File.read("./spec/fixtures/#{fixture}.json")) }
  let(:trogdir_change) { TrogdirChange.new(change_hash) }
  subject { ServiceObjects::HandleChange.new(trogdir_change) }

  context 'when personal email created' do
    let(:fixture) { 'create_personal_email' }

    it 'does not call any service objects' do
      expect_any_instance_of(ServiceObjects::AssignEmailAddress).to_not receive(:call)
      expect_any_instance_of(ServiceObjects::SyncGoogleAccount).to_not receive(:call)
      expect_any_instance_of(ServiceObjects::JoinGoogleGroup).to_not receive(:call)
      expect_any_instance_of(ServiceObjects::LeaveGoogleGroup).to_not receive(:call)
      expect_any_instance_of(ServiceObjects::DeprovisionGoogleAccount).to_not receive(:call)
      expect_any_instance_of(ServiceObjects::CancelDeprovisioningGoogleAccount).to_not receive(:call)
      expect_any_instance_of(ServiceObjects::ReprovisionGoogleAccount).to_not receive(:call)
      expect(Workers::Trogdir::ChangeFinish).to receive(:perform_async).with(kind_of(String), :skip)
      expect(Workers::Trogdir::ChangeError).to_not receive(:perform_async)

      subject.call
    end
  end

  context 'when affiliation added' do
    context 'when a reprovisionable email exists' do
      let(:fixture) { 'update_person_add_affiliation' }
      before { PersonEmail.create uuid: '00000000-0000-0000-0000-000000000000', address: 'bob.dole@biola.edu', state: :suspended }

      it 'calls ReprovisionGoogleAccount' do
        expect_any_instance_of(ServiceObjects::AssignEmailAddress).to_not receive(:call)
        expect_any_instance_of(ServiceObjects::SyncGoogleAccount).to_not receive(:call)
        expect_any_instance_of(ServiceObjects::JoinGoogleGroup).to_not receive(:call)
        expect_any_instance_of(ServiceObjects::LeaveGoogleGroup).to_not receive(:call)
        expect_any_instance_of(ServiceObjects::DeprovisionGoogleAccount).to_not receive(:call)
        expect_any_instance_of(ServiceObjects::CancelDeprovisioningGoogleAccount).to_not receive(:call)
        expect_any_instance_of(ServiceObjects::ReprovisionGoogleAccount).to receive(:call).and_return(:create)
        expect(Workers::Trogdir::ChangeFinish).to receive(:perform_async).with(kind_of(String), :create)
        expect(Workers::Trogdir::ChangeError).to_not receive(:perform_async)

        subject.call
      end
    end

    context "when a reprovisionable email doesn't exist" do
      let(:fixture) { 'create_employee_without_university_email' }

      it 'calls AssignEmailAddress' do
        expect_any_instance_of(ServiceObjects::AssignEmailAddress).to receive(:call).and_return(:create)
        expect_any_instance_of(ServiceObjects::SyncGoogleAccount).to_not receive(:call)
        expect_any_instance_of(ServiceObjects::JoinGoogleGroup).to_not receive(:call)
        expect_any_instance_of(ServiceObjects::LeaveGoogleGroup).to_not receive(:call)
        expect_any_instance_of(ServiceObjects::DeprovisionGoogleAccount).to_not receive(:call)
        expect_any_instance_of(ServiceObjects::CancelDeprovisioningGoogleAccount).to_not receive(:call)
        expect_any_instance_of(ServiceObjects::ReprovisionGoogleAccount).to_not receive(:call)
        expect(Workers::Trogdir::ChangeFinish).to receive(:perform_async).with(kind_of(String), :create)
        expect(Workers::Trogdir::ChangeError).to_not receive(:perform_async)

        subject.call
      end
    end
  end

  context 'when account info updated' do
    let(:fixture) { 'update_person' }

    it 'calls SyncGoogleAccount' do
      expect_any_instance_of(ServiceObjects::AssignEmailAddress).to_not receive(:call)
      expect_any_instance_of(ServiceObjects::SyncGoogleAccount).to receive(:call).and_return(:create)
      expect_any_instance_of(ServiceObjects::JoinGoogleGroup).to_not receive(:call)
      expect_any_instance_of(ServiceObjects::LeaveGoogleGroup).to_not receive(:call)
      expect_any_instance_of(ServiceObjects::DeprovisionGoogleAccount).to_not receive(:call)
      expect_any_instance_of(ServiceObjects::CancelDeprovisioningGoogleAccount).to_not receive(:call)
      expect_any_instance_of(ServiceObjects::ReprovisionGoogleAccount).to_not receive(:call)
      expect(Workers::Trogdir::ChangeFinish).to receive(:perform_async).with(kind_of(String), :create)
      expect(Workers::Trogdir::ChangeError).to_not receive(:perform_async)

      subject.call
    end
  end

  context 'when a group is joined' do
    let(:fixture) { 'join_group' }

    it 'calls JoinGoogleGroup' do
      allow(Settings).to receive_message_chain(:groups, :whitelist).and_return(['Politician', 'President'])
      expect_any_instance_of(ServiceObjects::AssignEmailAddress).to_not receive(:call)
      expect_any_instance_of(ServiceObjects::SyncGoogleAccount).to_not receive(:call)
      expect_any_instance_of(ServiceObjects::JoinGoogleGroup).to receive(:call).and_return(:update)
      expect_any_instance_of(ServiceObjects::LeaveGoogleGroup).to_not receive(:call)
      expect_any_instance_of(ServiceObjects::DeprovisionGoogleAccount).to_not receive(:call)
      expect_any_instance_of(ServiceObjects::CancelDeprovisioningGoogleAccount).to_not receive(:call)
      expect_any_instance_of(ServiceObjects::ReprovisionGoogleAccount).to_not receive(:call)
      expect(Workers::Trogdir::ChangeFinish).to receive(:perform_async).with(kind_of(String), :update)
      expect(Workers::Trogdir::ChangeError).to_not receive(:perform_async)

      subject.call
    end
  end

  context 'when a group is left' do
    let(:fixture) { 'leave_group' }

    it 'calls LeaveGoogleGroup' do
      allow(Settings).to receive_message_chain(:groups, :whitelist).and_return(['Politician', 'Congressman'])
      expect_any_instance_of(ServiceObjects::AssignEmailAddress).to_not receive(:call)
      expect_any_instance_of(ServiceObjects::SyncGoogleAccount).to_not receive(:call)
      expect_any_instance_of(ServiceObjects::JoinGoogleGroup).to_not receive(:call)
      expect_any_instance_of(ServiceObjects::LeaveGoogleGroup).to receive(:call).and_return(:update)
      expect_any_instance_of(ServiceObjects::DeprovisionGoogleAccount).to_not receive(:call)
      expect_any_instance_of(ServiceObjects::CancelDeprovisioningGoogleAccount).to_not receive(:call)
      expect_any_instance_of(ServiceObjects::ReprovisionGoogleAccount).to_not receive(:call)
      expect(Workers::Trogdir::ChangeFinish).to receive(:perform_async).with(kind_of(String), :update)
      expect(Workers::Trogdir::ChangeError).to_not receive(:perform_async)

      subject.call
    end
  end

  context 'when all affiliations removed' do
    let(:fixture) { 'update_person_remove_all_affiliations' }

    it 'calls DeprovisionGoogleAccount' do
      expect_any_instance_of(ServiceObjects::AssignEmailAddress).to_not receive(:call)
      expect_any_instance_of(ServiceObjects::SyncGoogleAccount).to_not receive(:call)
      expect_any_instance_of(ServiceObjects::JoinGoogleGroup).to_not receive(:call)
      expect_any_instance_of(ServiceObjects::LeaveGoogleGroup).to_not receive(:call)
      expect_any_instance_of(ServiceObjects::DeprovisionGoogleAccount).to receive(:call).and_return(:update)
      expect_any_instance_of(ServiceObjects::CancelDeprovisioningGoogleAccount).to_not receive(:call)
      expect_any_instance_of(ServiceObjects::ReprovisionGoogleAccount).to_not receive(:call)
      expect(Workers::Trogdir::ChangeFinish).to receive(:perform_async).with(kind_of(String), :update)
      expect(Workers::Trogdir::ChangeError).to_not receive(:perform_async)

      subject.call
    end
  end

  context 'when being deprovisioned and an affiliation is added' do
    let(:fixture) { 'update_person_add_affiliation' }

    before do
      email = PersonEmail.create uuid: '00000000-0000-0000-0000-000000000000', address: 'bob.dole@biola.edu'
      email.deprovision_schedules.create action: :delete, scheduled_for: 1.minute.from_now
    end

    it 'calls CancelDeprovisioningGoogleAccount' do
      expect_any_instance_of(ServiceObjects::AssignEmailAddress).to_not receive(:call)
      expect_any_instance_of(ServiceObjects::SyncGoogleAccount).to_not receive(:call)
      expect_any_instance_of(ServiceObjects::JoinGoogleGroup).to_not receive(:call)
      expect_any_instance_of(ServiceObjects::LeaveGoogleGroup).to_not receive(:call)
      expect_any_instance_of(ServiceObjects::DeprovisionGoogleAccount).to_not receive(:call)
      expect_any_instance_of(ServiceObjects::CancelDeprovisioningGoogleAccount).to receive(:call).and_return(:update)
      expect_any_instance_of(ServiceObjects::ReprovisionGoogleAccount).to_not receive(:call)
      expect(Workers::Trogdir::ChangeFinish).to receive(:perform_async).with(kind_of(String), :update)
      expect(Workers::Trogdir::ChangeError).to_not receive(:perform_async)

      subject.call
    end
  end
end
