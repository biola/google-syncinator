require 'spec_helper'

describe API::V1::AliasEmailsAPI, type: :unit do
  include Rack::Test::Methods
  include HMACHelpers

  let(:uuid) { '00000000-0000-0000-0000-000000000000' }
  let(:address) { 'bob.dole@biola.edu' }
  let(:account_email) { PersonEmail.create! uuid: uuid, address: address }
  let(:alias_address) { 'bobby.dole@biola.edu' }
  let!(:alias_email) { AliasEmail.create! account_email: account_email, address: alias_address }
  let(:method) { :get }
  let(:url) { '/v1/alias_emails' }
  let(:params) { {} }
  let(:response) { send "signed_#{method}".to_sym, url, params }
  let(:json) do
    js = JSON.parse(response.body)
    js = js.deep_symbolize_keys if js.respond_to? :deep_symbolize_keys
    js
  end

  subject { response }

  describe 'GET /v1/alias_emails/:id' do
    let(:url) { "/v1/alias_emails/#{alias_email.id}" }

    context 'when unauthenticated' do
      before { get url }
      subject { last_response }
      it { expect(subject.status).to eql 401 }
    end

    it { expect(subject.status).to eql 200 }

    it 'returns an alias email object' do
      expect(json).to eql id: alias_email.id.to_s, account_email_id: account_email.id.to_s, address: alias_email.address, state: alias_email.state.to_s, deprovision_schedules: []
    end
  end

  describe 'POST /v1/alias_emails' do
    let(:method) { :post }
    let(:ross_uuid) { '11111111-1111-1111-1111-111111111111' }
    let(:ross_address) { 'ross.perot@biola.edu' }
    let(:ross_alias) { 'rossie.perot@biola.edu' }
    let(:ross_account_email) { PersonEmail.create! uuid: ross_uuid, address: ross_address }
    let(:params) { {account_email_id: ross_account_email.id.to_s, address: ross_alias} }

    context 'when unauthenticated' do
      before { post url, params }
      subject { last_response }
      it { expect(subject.status).to eql 401 }
    end

    context 'when authenticated' do
      before do
        expect(TrogdirPerson).to receive(:new).with(ross_uuid).and_return double(biola_id: 1234567, first_or_preferred_name: 'Bob', last_name: 'Dole', title: nil, department: nil, privacy: false)
        expect_any_instance_of(GoogleAccount).to receive(:create_alias!)
      end

      it { expect(subject.status).to eql 201 }

      it 'creates an alias email object' do
        expect { subject }.to change(AliasEmail, :count).from(1).to 2
      end

      it 'returns an alias email object' do
        expect(json).to include id: an_instance_of(String), account_email_id: ross_account_email.id.to_s, address: ross_alias, state: 'active'
      end
    end
  end
end
