require 'spec_helper'

describe API::V1::EmailsAPI, type: :unit do
  include Rack::Test::Methods
  include HMACHelpers

  let(:uuids) { ['00000000-0000-0000-0000-000000000000'] }
  let(:address) { 'dole.for.pres@biola.edu' }
  let!(:email) { DepartmentEmail.create! address: address, uuids: uuids }
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

  before do
    allow_any_instance_of(GoogleAccount).to receive(:data).and_return(
      'name' => {'givenName' => 'Bob', 'familyName' => 'Dole'},
      'organizations' => ['department' => 'Office of the Pres', 'title' => 'Pres'],
      'includeInGlobalAddressList' => true,
      'orgUnitPath' => '/BabyKissers'
    )
  end

  describe 'GET /v1/department_emails/:id' do
    let(:url) { "/v1/department_emails/#{email.id}" }

    context 'when unauthenticated' do
      before { get url }
      subject { last_response }
      it { expect(subject.status).to eql 401 }
    end

    it { expect(subject.status).to eql 200 }

    it 'returns an email objects' do
      expect(json).to eql(
        id: email.id.to_s,
        address: email.address,
        uuids: email.uuids,
        first_name: 'Bob',
        last_name: 'Dole',
        department: 'Office of the Pres',
        title: 'Pres',
        privacy: false,
        org_unit_path: '/BabyKissers',
        state: email.state.to_s,
        deprovision_schedules: [],
        exclusions: []
      )
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
      before { expect_any_instance_of(GoogleAccount).to receive(:create!).with(first_name: 'Ross', last_name: 'Perot', department: 'Perot For Pres', title: 'Boss', privacy: false) }

      it { expect(subject.status).to eql 201 }

      it 'creates an email object' do
        expect { subject }.to change(DepartmentEmail, :count).from(1).to 2
      end

      it 'returns an email object' do
        expect(json).to include id: an_instance_of(String), address: 'perot.for.pres@biola.edu', uuids: ['11111111-1111-1111-1111-111111111111'], state: 'active', deprovision_schedules: [], exclusions: []
      end
    end
  end

  describe 'PUT /v1/department_emails/:id' do
    let(:alt_uuids) { ['00000000-0000-0000-0000-000000000001'] }
    let(:method) { :put }
    let(:url) { "/v1/department_emails/#{email.id}" }

    context 'with DepartmentEmail model attributes set' do
      let(:params) { {uuids: alt_uuids} }

      it 'updates the email object' do
        expect { subject }.to change { email.reload.uuids }.from(uuids).to alt_uuids
      end

      it 'does not update the Google API' do
        expect_any_instance_of(GoogleAccount).to_not receive :update!
        subject
      end
    end

    context 'with Google API attributes set' do
      let(:params) { {first_name: 'Bobby'} }

      it 'does not update the email object' do
        expect_any_instance_of(GoogleAccount).to receive :update!
        expect { subject }.to_not change { email.reload.uuids }
      end

      it 'updates the Google API' do
        expect_any_instance_of(GoogleAccount).to receive(:update!).with first_name: 'Bobby'
        subject
      end
    end

    context 'with DepartmentEmail model and Google API attributes set' do
      let(:params) { {uuids: alt_uuids, first_name: 'Bobby'} }

      it 'updates the email object and Google API' do
        expect_any_instance_of(GoogleAccount).to receive(:update!).with first_name: 'Bobby'
        expect { subject }.to change { email.reload.uuids }.from(uuids).to alt_uuids
      end

      it 'returns an email object' do
        expect_any_instance_of(GoogleAccount).to receive :update!
        expect(json).to include id: an_instance_of(String), address: 'dole.for.pres@biola.edu', uuids: ['00000000-0000-0000-0000-000000000001'], state: 'active', deprovision_schedules: [], exclusions: []
      end

      context 'when changing the address' do
        let(:params) { {address: 'vote.for.dole@biola.edu'} }

        it 'creates an Alias' do
          expect_any_instance_of(GoogleAccount).to receive(:update!).with address: 'vote.for.dole@biola.edu'
          expect { subject }.to change { AliasEmail.where(address: 'dole.for.pres@biola.edu').length }.from(0).to 1
        end
      end
    end
  end
end
