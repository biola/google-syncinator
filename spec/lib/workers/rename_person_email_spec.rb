require 'spec_helper'

describe Workers::RenamePersonEmail do
  let(:uuid) { '00000000-0000-0000-0000-000000000000' }
  let(:old_address) { 'bob.dole@biola.edu' }
  let(:new_address) { 'bobby.dole@biola.edu' }
  let(:biola_id) { 1234567 }
  let!(:email) { PersonEmail.create! uuid: uuid, address: old_address }
  subject { Workers::RenamePersonEmail.new }

  before do
    expect(TrogdirPerson).to receive(:new).with(uuid).and_return double(biola_id: biola_id)
    expect_any_instance_of(GoogleAccount).to receive(:rename!).with new_address
  end

  it 'renames the person email' do
    expect { subject.perform(email.id, new_address) }.to change { email.reload.address }.from(old_address).to new_address
  end

  it 'renames the trogdir email' do
    expect { subject.perform(email.id, new_address) }.to change(Workers::Trogdir::RenameEmail.jobs, :size).by(1)
  end

  it 'renames the legacy table' do
    expect { subject.perform(email.id, new_address) }.to change(Workers::LegacyEmailTable::Rename.jobs, :size).by(1)
  end
end
