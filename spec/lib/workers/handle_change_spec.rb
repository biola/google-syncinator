require 'spec_helper'

describe Workers::HandleChange do
  it 'calls the HandleChange service object' do
    expect_any_instance_of(ServiceObjects::HandleChange).to receive :call
    subject.perform({})
  end
end
