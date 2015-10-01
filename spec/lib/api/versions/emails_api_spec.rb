require 'spec_helper'

describe API::V1::EmailsAPI, type: :unit do
  include Rack::Test::Methods
  include HMACHelpers

  let(:uuid) { '00000000-0000-0000-0000-000000000000' }
  let(:address) { 'bob.dole@biola.edu' }
  let!(:email) { PersonEmail.create! uuid: uuid, address: address }
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
    let!(:ross) { PersonEmail.create! uuid: '11111111-1111-1111-1111-111111111111', address: 'ross.perot@biola.edu' }

    context 'when unauthenticated' do
      before { get url }
      subject { last_response }
      it { expect(subject.status).to eql 401 }
    end

    it { expect(subject.status).to eql 200 }

    it 'returns multiple email objects' do
      expect(json).to eql [
        {'_type' => email.class.to_s, 'id' => email.id.to_s, 'address' => email.address, 'state' => email.state.to_s, 'uuid' => email.uuid, 'deprovision_schedules' => email.deprovision_schedules.to_a, 'exclusions' => email.exclusions.to_a},
        {'_type' => ross.class.to_s, 'id' => ross.id.to_s, 'address' => ross.address, 'state' => ross.state.to_s, 'uuid' => ross.uuid, 'deprovision_schedules' => ross.deprovision_schedules.to_a, 'exclusions' => ross.exclusions.to_a}
      ]
    end

    context 'with multiple email types' do
      let!(:alias_email) { AliasEmail.create! account_email: ross, address: 'rossie.perot@biola.edu' }

      it 'returns different JSON attributes' do
        expect(json).to eql [
          {'_type' => email.class.to_s, 'id' => email.id.to_s, 'address' => email.address, 'state' => email.state.to_s, 'uuid' => email.uuid, 'deprovision_schedules' => email.deprovision_schedules.to_a, 'exclusions' => email.exclusions.to_a},
          {'_type' => ross.class.to_s, 'id' => ross.id.to_s, 'address' => ross.address, 'state' => ross.state.to_s, 'uuid' => ross.uuid, 'deprovision_schedules' => ross.deprovision_schedules.to_a, 'exclusions' => ross.exclusions.to_a},
          {'_type' => alias_email.class.to_s, 'id' => alias_email.id.to_s, 'address' => alias_email.address, 'state' => alias_email.state.to_s, 'account_email_id' => alias_email.account_email_id.to_s}
        ]
      end
    end

    context 'when searching' do
      let(:params) { {q: 'perot' } }

      it 'only returns matching email objects' do
        expect(json).to eql [
          {'_type' => 'PersonEmail', 'id' => ross.id.to_s, 'address' => ross.address, 'state' => ross.state.to_s, 'uuid' => ross.uuid, 'deprovision_schedules' => ross.deprovision_schedules.to_a, 'exclusions' => ross.exclusions.to_a}
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
      expect(json).to eql _type: 'PersonEmail', id: email.id.to_s, address: email.address, state: email.state.to_s, uuid: uuid, deprovision_schedules: [], exclusions: []
    end
  end
end
