# Version 1 of the person emails Grape API
class API::V1::PersonEmailsAPI < Grape::API
  include Grape::Kaminari

  resource :person_emails do
    desc 'Gets an individual person email'
    params do
      requires :id, type: String
    end
    get ':id' do
      email = PersonEmail.find(params[:id])

      present email, with: API::V1::PersonEmailEntity
    end

    desc 'Create an person email'
    params do
      requires :uuid, type: String
      requires :address, type: String
    end
    post do
      # NOTE: We need the email object back so don't preform asynchronously here
      email = Workers::CreatePersonEmail.new.perform(params[:uuid], params[:address])

      present email, with: API::V1::PersonEmailEntity
    end

    # NOTE: uuid will always be set to whatever is passed through.   
    desc 'Update a person email'
    params do
      optional :first_name, type: String
      optional :last_name, type: String
      optional :address, type: String
      optional :uuid, type: String
      optional :password, type: String
      optional :vfe, type: Boolean
      optional :privacy, type: Boolean
    end
    put ':id' do
      account_params = params.to_hash(symbolize_keys: true)
      email = Workers::UpdatePersonAccount.new.perform account_params

      present email, with: API::V1::PersonEmailEntity
    end
  end
end
