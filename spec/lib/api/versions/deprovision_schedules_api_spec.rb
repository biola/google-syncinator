require 'spec_helper'

describe API::V1::DeprovisionSchedulesAPI, type: :unit do
  include Rack::Test::Methods
  include HMACHelpers

  let(:uuid) { '00000000-0000-0000-0000-000000000000' }
  let(:address) { 'bob.dole@biola.edu' }
  let!(:email) { create :person_email, uuid: uuid, address: address }
  let!(:action) { 'delete' }
  let(:scheduled_for) { Time.now.iso8601(3) }
  let(:reason) { "Because I'm testing" }
  let(:method) { :post }
  let(:url) { "/v1/emails/#{email.id}/deprovision_schedules" }
  let(:params) { {} }
  let(:response) { send "signed_#{method}".to_sym, url, params }
  let(:json) do
    js = JSON.parse(response.body)
    js = js.deep_symbolize_keys if js.respond_to? :deep_symbolize_keys
    js
  end

  subject { response }

  describe 'POST /v1/emails/:email_id/deprovision_schedules' do
    let(:params) { {action: action, reason: reason, scheduled_for: scheduled_for} }

    context 'when unauthenticated' do
      before { post url, params }
      subject { last_response }
      it { expect(subject.status).to eql 401 }
    end

    context 'when authenticated' do
      it { expect(subject.status).to eql 201 }

      it 'creates an exclusion object' do
        expect { subject }.to change { email.reload.deprovision_schedules.count }.from(0).to 1
      end

      it 'returns an exclusion object' do
        expect(json).to include id: an_instance_of(String), email_id: email.id.to_s, action: action, reason: reason, scheduled_for: scheduled_for, completed_at: nil, canceled: nil
      end
    end
  end

  describe 'PUT /v1/emails/:email_id/deprovision_schedules/:deprovision_schedule_id' do
    let!(:deprovision_schedule) { email.deprovision_schedules.create action: action, reason: reason, scheduled_for: scheduled_for }
    let(:method) { :put }
    let(:url) { "/v1/emails/#{email.id}/deprovision_schedules/#{deprovision_schedule.id}" }
    let(:params) { {canceled: '1'} }

    context 'when unauthenticated' do
      before { delete url, params }
      subject { last_response }
      it { expect(subject.status).to eql 401 }
    end

    context 'when authenticated' do
      it { expect(subject.status).to eql 200 }

      it 'updates a deprovision schedule' do
        expect { subject }.to change { email.reload.deprovision_schedules.first.canceled }.from(nil).to true
      end

      it 'returns a deprovison_schedule object' do
        expect(json).to include id: an_instance_of(String), email_id: email.id.to_s, action: action, reason: reason, scheduled_for: scheduled_for, completed_at: nil, canceled: true
      end
    end
  end

  describe 'DELETE /v1/emails/:email_id/deprovision_schedules/:deprovision_schedule_id' do
    let!(:deprovision_schedule) { email.deprovision_schedules.create action: action, reason: reason, scheduled_for: scheduled_for }
    let(:method) { :delete }
    let(:url) { "/v1/emails/#{email.id}/deprovision_schedules/#{deprovision_schedule.id}" }

    context 'when unauthenticated' do
      before { delete url, params }
      subject { last_response }
      it { expect(subject.status).to eql 401 }
    end

    context 'when authenticated' do
      it { expect(subject.status).to eql 200 }

      it 'deletes a deprovision schedule' do
        expect { subject }.to change { email.reload.deprovision_schedules.count }.from(1).to 0
      end

      it 'returns a deprovison_schedule object' do
        expect(json).to include id: an_instance_of(String), email_id: email.id.to_s, action: action, reason: reason, scheduled_for: scheduled_for, completed_at: nil, canceled: nil
      end
    end
  end
end
