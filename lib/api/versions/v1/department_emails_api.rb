require './lib/api/versions/v1/helpers/email_helpers'

# Version 1 of the department emails Grape API
class API::V1::DepartmentEmailsAPI < Grape::API
  include Grape::Kaminari

  helpers  EmailHelpers

  resource :department_emails do
    desc 'Gets an individual department email'
    params do
      requires :id, type: String
    end
    get ':id' do
      email = prep_email(DepartmentEmail.find(params[:id]))
      present email, with: API::V1::DepartmentEmailEntity
    end

    desc 'Create a department email'
    params do
      requires :address, type: String
      requires :uuids, type: Array
      requires :first_name, type: String
      requires :last_name, type: String
      optional :password, type: String
      optional :department, type: String
      optional :title, type: String
      optional :privacy, type: Boolean
    end
    post do
      args = params.slice(:first_name, :last_name, :password, :department, :title, :privacy).to_hash(symbolize_keys: true)
      params[:org_unit_path] = Settings.organizational_units.department_emails

      GoogleAccount.new(params[:address]).create! args
      email = DepartmentEmail.create! address: params[:address], uuids: params[:uuids]

      email = prep_email(email)
      present email, with: API::V1::DepartmentEmailEntity
    end

    desc 'Update a department email'
    params do
      optional :address, type: String
      optional :uuids, type: Array
      optional :password, type: String
      optional :first_name, type: String
      optional :last_name, type: String
      optional :department, type: String
      optional :title, type: String
      optional :privacy, type: Boolean
    end
    put ':department_email_id' do
      email = DepartmentEmail.find(params[:department_email_id])
      old_address = email.address.dup

      api_args = params.slice(:address, :password, :first_name, :last_name, :department, :title, :privacy).to_hash(symbolize_keys: true)
      GoogleAccount.new(email.address).update! api_args if api_args.any?

      model_args = params.slice(:address, :uuids).to_hash(symbolize_keys: true)
      email.update! model_args if model_args.any?

      # Google will automatically create an alias of the old email when renaming the email address
      # so we need to reflect that locally
      if params.has_key?(:address) && params[:address] != old_address
        AliasEmail.create! address: old_address, account_email: email
      end

      email = prep_email(email)
      present email, with: API::V1::DepartmentEmailEntity
    end
  end
end
