require 'spec_helper'

describe API::V1::EmailsAPI, type: :unit do
  include Rack::Test::Methods
  include HMACHelpers

  let(:uuid) { '00000000-0000-0000-0000-000000000000' }
  let(:address) { 'bob.dole@biola.edu' }
  let!(:email) { create :person_email, uuid: uuid, address: address }
  let(:method) { :get }
  let(:url) { '/v1/person_emails' }
  let(:params) { {} }
  let(:response) { send "signed_#{method}".to_sym, url, params }
  let(:json) do
    js = JSON.parse(response.body)
    js = js.deep_symbolize_keys if js.respond_to? :deep_symbolize_keys
    js
  end

  subject { response }

  before do
    allow_any_instance_of(GoogleAccount).to receive(:data).and_return(
      'name' => {'givenName' => 'Bob', 'familyName' => 'Dole'},
      'organizations' => ['department' => 'Office of the Pres', 'title' => 'Pres'],
      'includeInGlobalAddressList' => true,
      'orgUnitPath' => '/BabyKissers'
    )
  end

  describe 'GET /v1/person_emails/:id' do
    let(:url) { "/v1/person_emails/#{email.id}" }

    context 'when unauthenticated' do
      before { get url }
      subject { last_response }
      it { expect(subject.status).to eql 401 }
    end

    it { expect(subject.status).to eql 200 }

    it 'returns an email objects' do
      expect(json).to eql id: email.id.to_s, uuid: email.uuid, address: email.address, state: email.state.to_s, vfe: false, first_name: 'Bob', last_name: 'Dole', privacy: false, deprovision_schedules: [], exclusions: [], alias_emails: []
    end
  end

  describe 'POST /v1/person_emails' do
    let(:method) { :post }
    let(:ross_uuid) { '11111111-1111-1111-1111-111111111111' }
    let(:ross_address) { 'ross.perot@biola.edu' }
    let(:params) { {uuid: ross_uuid, address: ross_address, primary: false} }

    context 'when unauthenticated' do
      before { post url, params }
      subject { last_response }
      it { expect(subject.status).to eql 401 }
    end

    context 'when authenticated' do
      before do
        expect(TrogdirPerson).to receive(:new).with(ross_uuid).and_return double(biola_id: 1234567, first_or_preferred_name: 'Bob', last_name: 'Dole', title: nil, department: nil, privacy: false, affiliations: ['alumnus'])
        expect_any_instance_of(GoogleAccount).to receive(:create!)
      end

      it { expect(subject.status).to eql 201 }

      it 'creates an email object' do
        expect { subject }.to change(PersonEmail, :count).from(1).to 2
      end

      it 'returns an email object' do
        expect(json).to include id: an_instance_of(String), uuid: '11111111-1111-1111-1111-111111111111', address: 'ross.perot@biola.edu', state: 'active', deprovision_schedules: [], exclusions: []
      end
    end
  end

  describe 'PUT /v1/person_emails/:id' do
    let(:alt_uuid) { '00000000-0000-0000-0000-000000000001' }
    let(:method) { :put }
    let(:new_address) { 'bobby.dole@biola.edu' }
    let(:url) { "/v1/person_emails/#{email.id}" }
    context 'when unauthenticated' do
      before { post url, params }
      subject { last_response }
      it { expect(subject.status).to eql 401 }
    end

    before do
      allow(TrogdirPerson).to receive(:new).with(uuid).and_return double(biola_id: 1234567)
      allow(TrogdirPerson).to receive(:new).with(alt_uuid).and_return double(biola_id: 1234567)
    end

    context 'with PersonEmail model attributes set' do
      let(:params) { {id: email.id, address: address, uuid: alt_uuid, first_name: nil, last_name: nil, password: nil, address: address, privacy: nil} }

      it 'updates the email object' do
        expect { subject }.to change { email.reload.uuid }.from(uuid).to alt_uuid
      end

      it ' not update the Google API' do
        expect_any_instance_of(GoogleAccount).to_not receive :update!
        subject
      end
    end

    context 'with Google API attributes set' do
      let(:params) { {id: email.id, address: address, uuid: uuid, first_name: 'Bobby', last_name: 'Doleo', password: 'one super password', address: address, privacy: true} }

      it 'does not update the email object' do
        expect_any_instance_of(GoogleAccount).to receive :update!
        expect { subject }.to_not change { email.reload.uuid }
      end

      it 'updates the Google API' do
        expect_any_instance_of(GoogleAccount).to receive(:update!).with first_name: 'Bobby', last_name: 'Doleo', password: 'one super password', privacy: true
        subject
      end
    end

    context 'with PersonEmail model and Google API attributes set' do
      let(:params) { {id: email.id, address: address, uuid: alt_uuid, first_name: 'Bobby', last_name: 'Doleo', password: 'one super password', address: address, privacy: true} }

      it 'updates the email object and Google API' do
        expect_any_instance_of(GoogleAccount).to receive(:update!).with first_name: 'Bobby', last_name: 'Doleo', password: 'one super password', privacy: true
        expect { subject }.to change { email.reload.uuid }.from(uuid).to alt_uuid
      end

      it 'returns an email object' do
        expect_any_instance_of(GoogleAccount).to receive :update!
        allow_any_instance_of(GoogleAccount).to receive(:data).and_return(
          'name' => {'givenName' => 'Bob', 'familyName' => 'Dole'},
          'organizations' => ['department' => '', 'title' => ''],
          'includeInGlobalAddressList' => true,
          'orgUnitPath' => '/'
        )
        expect(json).to include id: email.id, address: "bob.dole@biola.edu", first_name: "Bob", last_name: "Dole", state: 'active', vfe: nil, address: "bob.dole@biola.edu", uuid: "00000000-0000-0000-0000-000000000001", deprovision_schedules: [], exclusions: []
      end

      context 'when changing the address' do
        let(:params) { {id: email.id, address: new_address, uuid: alt_uuid, first_name: 'Bobby', last_name: 'Doleo', password: 'one super password', privacy: true} }

        it 'creates an Alias' do
          expect_any_instance_of(GoogleAccount).to receive(:update!).with first_name: 'Bobby', last_name: 'Doleo', password: 'one super password', privacy: true, address: 'bobby.dole@biola.edu'
          expect { subject }.to change { AliasEmail.where(address: 'bob.dole@biola.edu').length }.from(0).to 1
        end
      end
    end

    context 'when removing the owner and setting vfe' do
      let(:params) { { id: email.id, address: new_address, uuid: '' , vfe: true } }

      it 'updates the email object' do
        expect_any_instance_of(GoogleAccount).to receive(:update!).with address: 'bobby.dole@biola.edu'
        expect { subject }.to change { email.reload.uuid }.from(uuid).to nil
      end
    end
  end
end
