require 'spec_helper'

describe Workers::Trogdir::DeleteEmail, type: :unit do
  context 'when email exists' do
    before { expect_any_instance_of(Trogdir::APIClient::Emails).to receive_message_chain(:index, :perform).and_return double(success?: true, parse: ['id' => '12345', 'address' => 'bob.dole@biola.edu'])}

    it 'deletes an email in Trogdir' do
      expect_any_instance_of(Trogdir::APIClient::Emails).to receive_message_chain(:destroy, :perform).and_return(double(success?: true))
      Workers::Trogdir::DeleteEmail.new.perform('00000000-0000-0000-0000-000000000000', 'bob.dole@biola.edu')
    end
  end

  context 'when email already deleted' do
    before { expect_any_instance_of(Trogdir::APIClient::Emails).to receive_message_chain(:index, :perform).and_return double(success?: true, parse: [])}

    it 'does nothing' do
      expect_any_instance_of(Trogdir::APIClient::Emails).to_not receive(:destroy)
      Workers::Trogdir::DeleteEmail.new.perform('00000000-0000-0000-0000-000000000000', 'bob.dole@biola.edu')
    end
  end
end
