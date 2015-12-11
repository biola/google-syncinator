require 'spec_helper'

describe Emails::NotifyOfClosure, type: :unit do
  let(:account_email) { create :person_email, address: 'bob.dole@biola.edu' }
  let(:deprovision_schedule) { account_email.deprovision_schedules.create action: :notify_of_closure, scheduled_for: 1.minute.ago }
  before { account_email.deprovision_schedules.create action: :suspend, scheduled_for: 7.days.from_now }

  before { Mail::TestMailer.deliveries.clear }

  it 'sends an email' do
    expect(TrogdirPerson).to receive(:new).and_return(double(first_or_preferred_name: 'Bob'))
    expect { Emails::NotifyOfClosure.new(deprovision_schedule, account_email).send! }.to change { Mail::TestMailer.deliveries.length }.from(0).to 1
  end

  it 'sends to the right recipient' do
    expect(TrogdirPerson).to receive(:new).and_return(double(first_or_preferred_name: 'Bob'))
    Emails::NotifyOfClosure.new(deprovision_schedule, account_email).send!
    expect(Mail::TestMailer.deliveries.first.to).to eql ['bob.dole@biola.edu', account_email.address]
  end
end
