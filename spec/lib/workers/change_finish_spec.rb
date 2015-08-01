require 'spec_helper'

describe Workers::ChangeFinish, type: :unit do
  it 'marks the sync log as finished in Trogdir' do
    expect_any_instance_of(Trogdir::APIClient::ChangeSyncs).to receive_message_chain(:finish, :perform).and_return(double(success?: true))
    Workers::ChangeFinish.new.perform '12345', 'Testing'
  end
end
