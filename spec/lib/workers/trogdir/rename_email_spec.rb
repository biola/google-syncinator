require 'spec_helper'

describe Workers::Trogdir::RenameEmail do
  it 'renames an email in Trogdir' do
    expect_any_instance_of(Trogdir::APIClient::Emails).to receive_message_chain(:index, :perform).and_return double(success?: true, parse: ['id' => '12345', 'address' => 'bob.dole@biola.edu'])
    expect_any_instance_of(::Trogdir::APIClient::Emails).to receive_message_chain(:update, :perform).and_return(double(success?: true))
    Workers::Trogdir::RenameEmail.new.perform('00000000-0000-0000-0000-000000000000', 'bob.dole@biola.edu', 'bobby.dole@biola.edu')
  end
end
