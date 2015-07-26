require 'spec_helper'

describe Workers::DeprovisionGoogleAccount do
  let(:change_hash) { {'person_id' => '1111111-2222-3333-4444-555555555555'} }
  it 'calls ServiceObjects::DeprovisionGoogleAccount' do
    dga = double(ServiceObjects::DeprovisionGoogleAccount)
    expect(dga).to receive(:call)
    expect(ServiceObjects::DeprovisionGoogleAccount).to receive(:new).with(a_kind_of(TrogdirChange)).and_return dga
    subject.perform(change_hash)
  end
end
