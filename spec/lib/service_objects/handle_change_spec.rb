require 'spec_helper'

describe ServiceObjects::HandleChange do
  subject { ServiceObjects::HandleChange.new(change) }
  let(:change_hash) { JSON.parse(File.read('./spec/fixtures/create_user.json')) }
  let(:change) { TrogdirChange.new(change_hash) }

  context 'when personal email created' do
    let(:change_hash) { JSON.parse(File.read('./spec/fixtures/create_personal_email.json')) }

    it 'does not call any service objects' do
      expect_any_instance_of(ServiceObjects::AssignEmailAddress).to_not receive(:call)
      expect_any_instance_of(ServiceObjects::SyncGoogleAccount).to_not receive(:call)
      expect(Workers::ChangeFinish).to receive(:perform_async).with(kind_of(String), :skip)
      expect(Workers::ChangeError).to_not receive(:perform_async)

      subject.call
    end
  end

  context 'when affiliation added' do
    let(:change_hash) { JSON.parse(File.read('./spec/fixtures/create_user_without_university_email.json')) }

    it 'calls AssignEmailAddress' do
      expect_any_instance_of(ServiceObjects::AssignEmailAddress).to receive(:call).and_return(:create)
      expect_any_instance_of(ServiceObjects::SyncGoogleAccount).to_not receive(:call)
      expect(Workers::ChangeFinish).to receive(:perform_async).with(kind_of(String), :create)
      expect(Workers::ChangeError).to_not receive(:perform_async)

      subject.call
    end
  end

  context 'when university email created' do
    let(:change_hash) { JSON.parse(File.read('./spec/fixtures/create_email.json')) }

    it 'calls SyncGoogleAccount' do
      expect_any_instance_of(ServiceObjects::AssignEmailAddress).to_not receive(:call)
      expect_any_instance_of(ServiceObjects::SyncGoogleAccount).to receive(:call).and_return(:update)
      expect(Workers::ChangeFinish).to receive(:perform_async).with(kind_of(String), :update)
      expect(Workers::ChangeError).to_not receive(:perform_async)

      subject.call
    end
  end

  context 'when biola id updated' do
    let(:change_hash) { JSON.parse(File.read('./spec/fixtures/update_biola_id.json')) }

    it 'calls UpdateEmailAddress' do
      expect_any_instance_of(ServiceObjects::AssignEmailAddress).to_not receive(:call)
      expect_any_instance_of(ServiceObjects::UpdateEmailAddress).to receive(:call).and_return(:create)
      expect(Workers::ChangeFinish).to receive(:perform_async).with(kind_of(String), :create)
      expect(Workers::ChangeError).to_not receive(:perform_async)

      subject.call
    end
  end

  context 'when account info updated' do
    let(:change_hash) { JSON.parse(File.read('./spec/fixtures/update_person.json')) }

    it 'calls SyncGoogleAccount' do
      expect_any_instance_of(ServiceObjects::AssignEmailAddress).to_not receive(:call)
      expect_any_instance_of(ServiceObjects::SyncGoogleAccount).to receive(:call).and_return(:create)
      expect(Workers::ChangeFinish).to receive(:perform_async).with(kind_of(String), :create)
      expect(Workers::ChangeError).to_not receive(:perform_async)

      subject.call
    end
  end
end
