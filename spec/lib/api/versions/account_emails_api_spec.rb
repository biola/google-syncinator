require 'spec_helper'

describe API::V1::AccountEmailsAPI, type: :unit do
  include Rack::Test::Methods
  include HMACHelpers

  let(:uuid) { '00000000-0000-0000-0000-000000000000' }
  let(:address) { 'bob.dole@biola.edu' }
  let!(:email) { create :person_email, uuid: uuid, address: address }
  let!(:department_email) { create :department_email, address: 'dole.for.pres@biola.edu', uuids: [uuid] }
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

  describe 'GET /v1/account_emails' do
    let(:url) { "/v1/account_emails" }
    let(:params) { {q: 'biola.edu'} }

    context 'when unauthenticated' do
      before { get url }
      subject { last_response }
      it { expect(subject.status).to eql 401 }
    end

    it { expect(subject.status).to eql 200 }

    it 'return a PersonEmail and DepartmentEmail' do
      expect(json.length).to eql 2
      expect(json.first['_type']).to eql 'PersonEmail'
      expect(json.last['_type']).to eql 'DepartmentEmail'
    end
  end

  describe 'GET /v1/account_emails/:id' do
    let(:url) { "/v1/account_emails/#{email.id}" }

    context 'when unauthenticated' do
      before { get url }
      subject { last_response }
      it { expect(subject.status).to eql 401 }
    end

    it { expect(subject.status).to eql 200 }

    context 'when a PersonEmail' do
      it 'returns PersonEmail attributes' do
        expect(json).to eql id: email.id.to_s, _type: 'PersonEmail', address: email.address, state: email.state.to_s, vfe: email.vfe, deprovision_schedules: [], exclusions: [], uuid: email.uuid
      end
    end

    context 'when a DepartmentEmail' do
      let(:email) { department_email }

      it 'returns DepartmentEmail attributes' do
        expect(json).to eql id: email.id.to_s, _type: 'DepartmentEmail', address: email.address, state: email.state.to_s, vfe: email.vfe, deprovision_schedules: [], exclusions: [], uuids: email.uuids
      end
    end
  end
end
