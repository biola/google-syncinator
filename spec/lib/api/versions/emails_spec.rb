require 'spec_helper'

describe API::V1, type: :unit do
  include Rack::Test::Methods
  include HMACHelpers

  let(:uuid) { '00000000-0000-0000-0000-000000000000' }
  let(:address) { 'bob.dole@biola.edu' }
  let!(:email) { UniversityEmail.create uuid: uuid, address: address, primary: true }
  let(:method) { :get }
  let(:url) { '/v1/emails' }
  let(:params) { {} }
  let(:response) { send "signed_#{method}".to_sym, url, params }
  let(:json) do
    js = JSON.parse(response.body)
    js = js.deep_symbolize_keys if js.respond_to? :deep_symbolize_keys
    js
  end

  subject { response }

  describe 'GET /v1/emails' do
    let!(:ross) { UniversityEmail.create uuid: '11111111-1111-1111-1111-111111111111', address: 'ross.perot@biola.edu', primary: false }

    context 'when unauthenticated' do
      before { get url }
      subject { last_response }
      it { expect(subject.status).to eql 401 }
    end

    it { expect(subject.status).to eql 200 }

    it 'returns multiple email objects' do
      expect(json).to eql [
        {'id' => email.id.to_s, 'uuid' => email.uuid, 'address' => email.address, 'primary' => email.primary, 'state' => email.state.to_s, 'deprovision_schedules' => [], 'exclusions' => []},
        {'id' => ross.id.to_s, 'uuid' => ross.uuid, 'address' => ross.address, 'primary' => ross.primary, 'state' => ross.state.to_s, 'deprovision_schedules' => [], 'exclusions' => []}
      ]
    end

    context 'when searching' do
      let(:params) { {q: 'perot' } }

      it 'only returns matching email objects' do
        expect(json).to eql [
          {'id' => ross.id.to_s, 'uuid' => ross.uuid, 'address' => ross.address, 'primary' => ross.primary, 'state' => ross.state.to_s, 'deprovision_schedules' => [], 'exclusions' => []}
        ]
      end
    end
  end

  describe 'GET /v1/emails/:id' do
    let(:url) { "/v1/emails/#{email.id}" }

    context 'when unauthenticated' do
      before { get url }
      subject { last_response }
      it { expect(subject.status).to eql 401 }
    end

    it { expect(subject.status).to eql 200 }

    it 'returns an email objects' do
      expect(json).to eql id: email.id.to_s, uuid: email.uuid, address: email.address, primary: email.primary, state: email.state.to_s, deprovision_schedules: [], exclusions: []
    end
  end

  describe 'POST /v1/emails' do
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
        expect(TrogdirPerson).to receive(:new).with(ross_uuid).and_return double(biola_id: 1234567)
      end

      it { expect(subject.status).to eql 201 }

      it 'creates an email object' do
        expect { subject }.to change(UniversityEmail, :count).from(1).to 2
      end

      it 'returns an email object' do
        expect(json).to include id: an_instance_of(String), uuid: '11111111-1111-1111-1111-111111111111', address: 'ross.perot@biola.edu', primary: false, state: 'active', deprovision_schedules: [], exclusions: []
      end
    end
  end

  describe 'PUT /v1/emails/:id' do
    let(:method) { :put }
    let(:url) { "/v1/emails/#{email.id}" }
    let(:params) { {primary: false} }

    context 'when unauthenticated' do
      before { put url, params }
      subject { last_response }
      it { expect(subject.status).to eql 401 }
    end

    it { expect(subject.status).to eql 200 }

    it 'updates an email object' do
      expect { subject }.to change { email.reload.primary }.from(true).to false
    end

    it 'returns an email object' do
      expect(json).to include id: email.id.to_s, uuid: email.uuid, address: email.address, primary: params[:primary], state: email.state.to_s, deprovision_schedules: [], exclusions: []
    end
  end
end
