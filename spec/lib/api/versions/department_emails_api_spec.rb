require 'spec_helper'

describe API::V1::EmailsAPI, type: :unit do
  include Rack::Test::Methods
  include HMACHelpers

  let(:uuids) { ['00000000-0000-0000-0000-000000000000'] }
  let(:address) { 'dole.for.pres@biola.edu' }
  let!(:email) { DepartmentEmail.create address: address, uuids: uuids }
  let(:method) { :get }
  let(:url) { '/v1/department_emails' }
  let(:params) { {} }
  let(:response) { send "signed_#{method}".to_sym, url, params }
  let(:json) do
    js = JSON.parse(response.body)
    js = js.deep_symbolize_keys if js.respond_to? :deep_symbolize_keys
    js
  end

  subject { response }

  describe 'GET /v1/department_emails/:id' do
    let(:url) { "/v1/department_emails/#{email.id}" }

    context 'when unauthenticated' do
      before { get url }
      subject { last_response }
      it { expect(subject.status).to eql 401 }
    end

    it { expect(subject.status).to eql 200 }

    it 'returns an email objects' do
      expect(json).to eql id: email.id.to_s, address: email.address, uuids: email.uuids, state: email.state.to_s, deprovision_schedules: [], exclusions: []
    end
  end

  describe 'POST /v1/department_emails' do
    let(:method) { :post }
    let(:ross_uuids) { ['11111111-1111-1111-1111-111111111111'] }
    let(:ross_address) { 'perot.for.pres@biola.edu' }
    let(:params) { {address: ross_address, uuids: ross_uuids, first_name: 'Ross', last_name: 'Perot', department: 'Perot For Pres', title: 'Boss', privacy: false} }

    context 'when unauthenticated' do
      before { post url, params }
      subject { last_response }
      it { expect(subject.status).to eql 401 }
    end

    context 'when authenticated' do
      before { expect_any_instance_of(GoogleAccount).to receive(:create!).with('Ross', 'Perot', 'Perot For Pres', 'Boss', false) }

      it { expect(subject.status).to eql 201 }

      it 'creates an email object' do
        expect { subject }.to change(DepartmentEmail, :count).from(1).to 2
      end

      it 'returns an email object' do
        expect(json).to include id: an_instance_of(String), address: 'perot.for.pres@biola.edu', uuids: ['11111111-1111-1111-1111-111111111111'], state: 'active', deprovision_schedules: [], exclusions: []
      end
    end
  end
end
