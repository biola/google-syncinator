require 'spec_helper'

describe Workers::CreateEmail, type: :unit do
  let(:uuid) { '00000000-0000-0000-0000-000000000000' }
  let(:address) { 'bob.dole@biola.edu' }
  let(:primary) { true }
  let(:biola_id) { 1234567 }
  subject { Workers::CreateEmail.new }

  before do
    expect(TrogdirPerson).to receive(:new).with(uuid).and_return double(biola_id: biola_id)
  end

  it 'creates a university email' do
    expect { subject.perform(uuid, address, primary) }.to change { UniversityEmail.count }.from(0).to 1
    expect(UniversityEmail.first.attributes).to include 'uuid' => uuid, 'address' => address, 'primary' => primary
  end

  it 'creates a trogdir email' do
    expect { subject.perform(uuid, address) }.to change(Workers::Trogdir::CreateEmail.jobs, :size).by(1)
  end

  it 'updates the legacy table' do
    expect { subject.perform(uuid, address) }.to change(Workers::LegacyEmailTable::Insert.jobs, :size).by(1)
  end
end
