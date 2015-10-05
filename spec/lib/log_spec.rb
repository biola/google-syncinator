require 'spec_helper'

describe Log, type: :unit do
  Log::LEVELS.each do |level|
    describe "##{level}" do
      context 'when in dry run mode' do
        before { expect(Settings).to receive(:dry_run).and_return true }

        it 'prepends "DRY RUN:"' do
          expect(Log.send(:logger)).to receive(:info).with 'DRY RUN: TEST MESSAGE'
          Log.info 'TEST MESSAGE'
        end
      end

      context 'when not in dry run mode' do
        it 'does not change the message' do
          expect(Log.send(:logger)).to receive(:info).with 'TEST MESSAGE'
          Log.info 'TEST MESSAGE'
        end
      end
    end
  end
end
