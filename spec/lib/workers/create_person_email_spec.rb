require 'spec_helper'

describe Workers::CreatePersonEmail, type: :unit do
  let(:uuid) { '00000000-0000-0000-0000-000000000000' }
  let(:address) { 'bob.dole@biola.edu' }
  let(:biola_id) { 1234567 }
  subject { Workers::CreatePersonEmail.new }

  before do
    expect(TrogdirPerson).to receive(:new).with(uuid).and_return double(biola_id: biola_id, first_or_preferred_name: 'Bob', last_name: 'Dole', title: nil, department: nil, privacy: false)
    expect_any_instance_of(GoogleAccount).to receive(:create!)
  end

  it 'creates a person email' do
    expect { subject.perform(uuid, address) }.to change { PersonEmail.count }.from(0).to 1
    expect(PersonEmail.first.attributes).to include 'uuid' => uuid, 'address' => address
  end

  it 'creates a trogdir email' do
    expect { subject.perform(uuid, address) }.to change(Workers::Trogdir::CreateEmail.jobs, :size).by(1)
  end

  it 'updates the legacy table' do
    expect { subject.perform(uuid, address) }.to change(Workers::LegacyEmailTable::Insert.jobs, :size).by(1)
  end
end
