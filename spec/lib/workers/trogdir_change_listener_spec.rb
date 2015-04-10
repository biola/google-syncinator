require 'spec_helper'

describe Workers::TrogdirChangeListener do
  subject { Workers::TrogdirChangeListener.new }
  let(:success) { true }
  let(:change_syncs) { [] }

  before do
    response = double(Trogdir::APIClient::ChangeSyncs, success?: success, parse: change_syncs)
    allow_any_instance_of(Workers::TrogdirChangeListener).to receive_message_chain(:change_syncs, :start, perform: response)
  end

  context 'with no change syncs' do
    it 'does not call any workers' do
      expect(Workers::AssignEmailAddress).to_not receive(:perform_async)
      expect(Workers::SyncGoogleAppsAccount).to_not receive(:perform_async)
      expect(Workers::TrogdirChangeListener).to_not receive(:perform_async)

      expect(subject.perform).to be_falsey
    end
  end

  context 'when personal email created' do
    let(:change_syncs) { [JSON.parse(File.read('./spec/fixtures/create_personal_email.json'))] }

    it 'does not call any workers' do
      expect(Workers::AssignEmailAddress).to_not receive(:perform_async)
      expect(Workers::SyncGoogleAppsAccount).to_not receive(:perform_async)
      expect(Workers::TrogdirChangeFinishWorker).to receive(:perform_async)
      expect(Workers::TrogdirChangeListener).to receive(:perform_async)

      expect(subject.perform).to be_falsey
    end
  end

  context 'when a trogdir-api error' do
    let(:success) { false }
    let(:change_syncs) { {'error' => 'Oopsie!'} }

    it 'raises a TrogdirAPIError' do
      expect(Workers::AssignEmailAddress).to_not receive(:perform_async)
      expect(Workers::SyncGoogleAppsAccount).to_not receive(:perform_async)

      expect { subject.perform }.to raise_error Workers::TrogdirChangeListener::TrogdirAPIError
    end
  end

  context 'when affiliation added' do
    let(:change_syncs) { [JSON.parse(File.read('./spec/fixtures/create_user_without_university_email.json'))] }

    it 'calls AssignEmailAddress worker' do
      expect(Workers::AssignEmailAddress).to receive(:perform_async)
      expect(Workers::SyncGoogleAppsAccount).to_not receive(:perform_async)
      expect(Workers::TrogdirChangeListener).to receive(:perform_async)

      subject.perform
    end
  end

  context 'when university email created' do
    let(:change_syncs) { [JSON.parse(File.read('./spec/fixtures/create_email.json'))] }

    it 'calls SyncGoogleAppsAccount worker' do
      expect(Workers::AssignEmailAddress).to_not receive(:perform_async)
      expect(Workers::SyncGoogleAppsAccount).to receive(:perform_async)
      expect(Workers::TrogdirChangeListener).to receive(:perform_async)

      subject.perform
    end
  end

  context 'when account info updated' do
    let(:change_syncs) { [JSON.parse(File.read('./spec/fixtures/update_person.json'))] }

    it 'calls SyncGoogleAppsAccount worker' do
      expect(Workers::AssignEmailAddress).to_not receive(:perform_async)
      expect(Workers::SyncGoogleAppsAccount).to receive(:perform_async)
      expect(Workers::TrogdirChangeListener).to receive(:perform_async)

      subject.perform
    end
  end
end
