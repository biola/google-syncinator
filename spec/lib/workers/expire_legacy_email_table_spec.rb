require 'spec_helper'

describe Workers::ExpireLegacyEmailTable do
  let(:biola_id) { 1234567 }
  let(:email_adddress) { 'bob.dole@biola.edu' }

  context 'when record does not exist' do
    it 'raises an error' do
      expect { subject.perform(biola_id, email_adddress) }.to raise_exception(Workers::ExpireLegacyEmailTable::RowNotFound)
    end
  end

  context 'when record exists' do
    after { DB[:email].truncate }

    context 'when expiration_date and reusable_date are nil' do
      before { DB[:email].insert idnumber: biola_id, email: email_adddress }

      it 'sets the dates' do
        expect { subject.perform(biola_id, email_adddress) }.to change { DB[:email].select_map([:expiration_date, :reusable_date]).first.map(&:class) }.from([NilClass, NilClass]).to [Time, Time]
      end
    end

    context 'when expiration_date and reusable_date are before expire_on and reusable on' do
      before { DB[:email].insert idnumber: biola_id, email: email_adddress, expiration_date: 8.day.ago, reusable_date: 1.day.ago }

      it 'does nothing' do
        expect { subject.perform(biola_id, email_adddress) }.to_not change { DB[:email].select_map([:expiration_date, :reusable_date]).first }
      end
    end

    context 'when expiration_date and reusable_date are after expire_on and reusable on' do
      before { DB[:email].insert idnumber: biola_id, email: email_adddress, expiration_date: 1.day.from_now, reusable_date: 8.day.from_now }

      it 'sets the earlier dates' do
        expect { subject.perform(biola_id, email_adddress) }.to change { DB[:email].select_map([:expiration_date, :reusable_date]).first }
      end
    end
  end
end
