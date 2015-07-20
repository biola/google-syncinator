require 'spec_helper'

describe Workers::CreateTrogdirEmail do
  it 'creates an email in Trogdir' do
    expect_any_instance_of(Trogdir::APIClient::Emails).to receive_message_chain(:create, :perform).and_return(double(success?: true))
    Workers::CreateTrogdirEmail.new.perform('00000000-0000-0000-0000-000000000000', 'bob.dole@biola.edu')
  end
end
