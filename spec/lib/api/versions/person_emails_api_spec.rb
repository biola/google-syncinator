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

  describe 'GET /v1/person_emails/:id' do
    let(:url) { "/v1/person_emails/#{email.id}" }

    context 'when unauthenticated' do
      before { get url }
      subject { last_response }
      it { expect(subject.status).to eql 401 }
    end

    it { expect(subject.status).to eql 200 }

    it 'returns an email objects' do
      expect(json).to eql id: email.id.to_s, uuid: email.uuid, address: email.address, state: email.state.to_s, deprovision_schedules: [], exclusions: [], alias_emails: []
    end
  end

  describe 'POST /v1/person_emails' do
    let(:method) { :post }
    let(:ross_uuid) { '11111111-1111-1111-1111-111111111111' }
    let(:ross_address) { 'ross.perot@biola.edu' }
    let(:params) { {uuid: ross_uuid, address: ross_address} }

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
    let(:method) { :put }
    let(:url) { "/v1/person_emails/#{email.id}" }
    let(:new_address) { 'bobby.dole@biola.edu' }
    let(:params) { {id: email.id, uuid: uuid, address: new_address, first_name: 'Bob', last_name: 'Dole', password: '1234', vfe: false, privacy: false} }

    context 'when unauthenticated' do
      before { post url, params }
      subject { last_response }
      it { expect(subject.status).to eql 401 }
    end

    context 'when authenticated' do
      before do
        expect(TrogdirPerson).to receive(:new).with(uuid).and_return double(biola_id: 1234567)
        expect_any_instance_of(GoogleAccount).to receive(:update!).with(new_address)
      end

      it { expect(subject.status).to eql 200 }

      it 'creates an email object' do
        expect { subject }.to change { email.reload.address }.from('bob.dole@biola.edu').to 'bobby.dole@biola.edu'
      end

      it 'returns an email object' do
        expect(json).to include id: an_instance_of(String), uuid: '00000000-0000-0000-0000-000000000000', address: 'bobby.dole@biola.edu', state: 'active', deprovision_schedules: [], exclusions: []
      end
    end
  end
end
