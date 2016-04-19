require 'spec_helper'

describe Whitelist, type: :unit do
  describe '.filter' do
    before { expect(Settings).to receive_message_chain(:groups, :whitelist).and_return ['Dorm 1', 'Dorm 2'] }
    it { expect(Whitelist.filter([])). to eql [] }
    it { expect(Whitelist.filter(['Dorm 3', 'Dorm 4'])). to eql [] }
    it { expect(Whitelist.filter(['Dorm 1', 'Dorm 4'])). to eql ['Dorm 1'] }
  end
end
