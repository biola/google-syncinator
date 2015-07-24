require 'spec_helper'

describe Workers::Deprovisioning::Activate do
  let(:uuid) { '00000000-0000-0000-0000-000000000000' }
  let(:address) { 'bob.dole@biola.edu' }
  let(:email) { UniversityEmail.create uuid: uuid, address: address, state: state}

  before do
    Workers::CreateTrogdirEmail.jobs.clear
    Workers::UnexpireLegacyEmailTable.jobs.clear
  end

  describe '#perform' do
    context 'when email is already active' do
      let(:state) { :active }

      it 'does nothing' do
        subject.perform(email.id)
        expect(email.deprovision_schedules).to be_empty
        expect(email.state).to eql :active
        expect(Workers::CreateTrogdirEmail.jobs).to be_empty
        expect(Workers::UnexpireLegacyEmailTable.jobs).to be_empty
      end
    end

    context 'when email is suspended' do
      let(:state) { :suspended }

      before { expect_any_instance_of(TrogdirPerson).to receive(:biola_id).and_return 1234567 }

      it 'activates the email' do
        expect { subject.perform(email.id) }.to change { email.reload.deprovision_schedules.count }.by 1
      end

      it 'adds an activate deprovision schedule' do
        expect { subject.perform(email.id) }.to change { email.reload.state }.from(:suspended).to :active
      end

      it 'creates a Trogdir email' do
        expect { subject.perform(email.id) }.to change(Workers::CreateTrogdirEmail.jobs, :size).by 1
      end

      it 'unexpires the legacy email table' do
        expect { subject.perform(email.id) }.to change(Workers::UnexpireLegacyEmailTable.jobs, :size).by 1
      end
    end
  end
end
