# Version 1 of the Emails Grape API
class API::V1::AliasEmailsAPI < Grape::API
  include Grape::Kaminari

  resource :alias_emails do
    desc 'Gets an individual alias email'
    params do
      requires :id, type: String
    end
    get ':id' do
      email = AliasEmail.find(params[:id])

      present email, with: API::V1::AliasEmailEntity
    end

    desc 'Create an alias email'
    params do
      requires :account_email_id, type: String
      requires :address, type: String
    end
    post do
      # NOTE: We need the email object back so don't preform asynchronously here
      email = Workers::CreateAliasEmail.new.perform(params[:account_email_id], params[:address])

      present email, with: API::V1::AliasEmailEntity
    end
  end
end
