require 'spec_helper'

describe API::V1::ExclusionsAPI, type: :unit do
  include Rack::Test::Methods
  include HMACHelpers

  let(:uuid) { '00000000-0000-0000-0000-000000000000' }
  let(:address) { 'bob.dole@biola.edu' }
  let!(:email) { UniversityEmail.create uuid: uuid, address: address, primary: true }
  let(:method) { :post }
  let(:url) { "/v1/emails/#{email.id}/exclusions" }
  let(:params) { {} }
  let(:response) { send "signed_#{method}".to_sym, url, params }
  let(:json) do
    js = JSON.parse(response.body)
    js = js.deep_symbolize_keys if js.respond_to? :deep_symbolize_keys
    js
  end

  subject { response }

  describe 'POST /v1/emails/:email_id/exclusions' do
    let(:creator_uuid) { '11111111-1111-1111-1111-111111111111' }
    let(:starts_at) { Time.now.iso8601(3) }
    let(:ends_at) { 1.month.from_now.iso8601(3) }
    let(:reason) { "Because I'm testing" }
    let(:params) { {creator_uuid: creator_uuid, starts_at: starts_at, ends_at: ends_at, reason: reason} }

    context 'when unauthenticated' do
      before { post url, params }
      subject { last_response }
      it { expect(subject.status).to eql 401 }
    end

    context 'when authenticated' do
      it { expect(subject.status).to eql 201 }

      it 'creates an exclusion object' do
        expect { subject }.to change { email.reload.exclusions.count }.from(0).to 1
      end

      it 'returns an exclusion object' do
        expect(json).to include id: an_instance_of(String), creator_uuid: creator_uuid, starts_at: starts_at.to_s, ends_at: ends_at.to_s, reason: reason
      end
    end
  end
end
