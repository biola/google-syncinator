require 'spec_helper'

describe TrogdirPerson do
  before { expect_any_instance_of(Trogdir::APIClient::People).to receive_message_chain(:show, :perform).and_return(double(success?: true, parse: hash)) }
  subject { TrogdirPerson.new('00000000-0000-0000-0000-000000000000') }

  describe '#first_name' do
    let(:hash) { {'first_name' => 'Bob'} }
    it { expect(subject.first_name).to eql 'Bob' }
  end

  describe '#last_name' do
    let(:hash) { {'last_name' => 'Dole'} }
    it { expect(subject.last_name).to eql 'Dole' }
  end

  describe '#department' do
    let(:hash) { {'department' => 'Office of the President'} }
    it { expect(subject.department).to eql 'Office of the President' }
  end

  describe '#title' do
    let(:hash) { {'title' => 'POTUS'} }
    it { expect(subject.title).to eql 'POTUS' }
  end

  describe '#privacy' do
    let(:hash) { {'privacy' => true} }
    it { expect(subject.privacy).to eql true }
  end

  describe '#biola_id' do
    let(:hash) { {'ids' => ['type' => 'biola_id', 'identifier' => 1234567]} }
    it { expect(subject.biola_id).to eql 1234567 }
  end

  describe '#first_or_preferred_name' do
    context 'with no preferred_name' do
      let(:hash) { {'preferred_name' => nil, 'first_name' => 'Robert'} }
      it { expect(subject.first_or_preferred_name).to eql 'Robert' }
    end

    context 'with a preferred_name' do
      let(:hash) { {'preferred_name' => 'Bob', 'first_name' => 'Robert'} }
      it { expect(subject.first_or_preferred_name).to eql 'Bob' }
    end
  end
end
