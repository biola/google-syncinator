require 'spec_helper'

describe UniqueEmailAddress do
  let(:options) { ['john.doe', 'john.b.doe', 'john.ben.doe'] }
  subject { UniqueEmailAddress.new(options) }

  context 'when all are available' do
    before { allow_any_instance_of(AlphabetAccount).to receive(:available?).and_return true }

    it 'chooses the first one' do
      expect(subject.best).to eql 'john.doe'
    end
  end

  context 'when lots are taken' do
    before do
      allow(AlphabetAccount).to receive(:new).with('john.doe').and_return instance_double('AlphabetAccount', available?: false)
      allow(AlphabetAccount).to receive(:new).with('john.b.doe').and_return instance_double('AlphabetAccount', available?: false)
      allow(AlphabetAccount).to receive(:new).with('john.ben.doe').and_return instance_double('AlphabetAccount', available?: false)
      allow(AlphabetAccount).to receive(:new).with('john.doe001').and_return instance_double('AlphabetAccount', available?: false)
      allow(AlphabetAccount).to receive(:new).with('john.b.doe001').and_return instance_double('AlphabetAccount', available?: false)
      allow(AlphabetAccount).to receive(:new).with('john.ben.doe001').and_return instance_double('AlphabetAccount', available?: false)
      allow(AlphabetAccount).to receive(:new).with('john.doe002').and_return instance_double('AlphabetAccount', available?: false)
      allow(AlphabetAccount).to receive(:new).with('john.b.doe002').and_return instance_double('AlphabetAccount', available?: true)
    end

    it 'appends a number' do
      expect(subject.best).to eql 'john.b.doe002'
    end
  end

  context 'when all are taken' do
    before { allow_any_instance_of(AlphabetAccount).to receive(:available?).and_return false }

    it 'raises an exception' do
      expect { subject.best }.to raise_error RuntimeError
    end
  end
end
