require 'spec_helper'

describe OrganizationalUnit do
  let(:affiliations) { [] }
  subject { OrganizationalUnit.path_for(affiliations) }

  context 'when affiliations param responds to #affilations' do
    let(:affiliations) { instance_double(TrogdirPerson, affiliations: ['employee']) }

    it 'returns the org unit' do
      expect(Settings).to receive(:organizational_units).and_return :'/Employees' => ['employee']
      expect(subject).to eql '/Employees'
    end
  end

  context 'when affiliations match one org unit' do
    let(:affiliations) { %w{employee} }

    it 'returns the org unit' do
      expect(Settings).to receive(:organizational_units).and_return :'/Employees' => %w{employee}
      expect(subject).to eql '/Employees'
    end
  end


  context 'when affiliations match multiple org units' do
    let(:affiliations) { %w{employee alumnus} }

    it 'returns the org unit from the first match' do
      expect(Settings).to receive(:organizational_units).and_return :'/Employees' => %w{faculty employee}, :'/Alumni' => %w{alumnus}
      expect(subject).to eql '/Employees'
    end
  end

  context 'when no affiliations match' do
    it 'returns the default org unit' do
      expect(subject).to eql OrganizationalUnit::DEFAULT_ORG_UNIT
    end
  end
end
