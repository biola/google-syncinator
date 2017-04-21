require './lib/api/versions/v1/helpers/email_helpers'

# Version 1 of the person emails Grape API
class API::V1::PersonEmailsAPI < Grape::API
  include Grape::Kaminari

  helpers  EmailHelpers

  resource :person_emails do
    desc 'Gets an individual person email'
    params do
      requires :id, type: String
    end
    get ':id' do
      email = PersonEmail.find(params[:id])

      email = prep_email(email)

      present email, with: API::V1::PersonEmailEntity
    end

    desc 'Create an person email'
    params do
      requires :uuid, type: String
      requires :address, type: String
      optional :primary, type: Boolean
    end
    post do
      # NOTE: We need the email object back so don't preform asynchronously here
      email = Workers::CreatePersonEmail.new.perform(params[:uuid], params[:address], params[:primary])

      email = prep_email(email)

      present email, with: API::V1::PersonEmailEntity
    end

    # NOTE: uuid will always be set to whatever is passed through and should be an empty string if the owner is being removed.
    desc 'Update a person email'
    params do
      requires :address, type: String
      optional :uuid, type: String
      optional :first_name, type: String
      optional :last_name, type: String
      optional :password, type: String
      optional :vfe, type: Boolean
      optional :privacy, type: Boolean
    end
    put ':id' do
      # We need the email object back so don't perform asynchronously here
      email = Workers::UpdatePersonEmail.new(
                                              id: params['id'],
                                              uuid: params['uuid'],
                                              address: params['address'],
                                              first_name: params['first_name'],
                                              last_name: params['last_name'],
                                              password: params['password'],
                                              vfe: params['vfe'],
                                              privacy: params['privacy']
                                             ).perform

      email = prep_email(email)

      present email, with: API::V1::PersonEmailEntity
    end
  end
end
