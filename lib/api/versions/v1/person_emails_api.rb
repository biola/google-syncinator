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

    desc 'Rename a person email'
    params do
      requires :address, type: String
    end
    put ':id' do
      # NOTE: We need the email object back so don't preform asynchronously here
      email = Workers::RenamePersonEmail.new.perform params['id'], params['address']

      present email, with: API::V1::PersonEmailEntity
    end
  end
end
