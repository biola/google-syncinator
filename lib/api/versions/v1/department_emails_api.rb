# Version 1 of the department emails Grape API
class API::V1::DepartmentEmailsAPI < Grape::API
  include Grape::Kaminari

  resource :department_emails do
    desc 'Gets an individual department email'
    params do
      requires :id, type: String
    end
    get ':id' do
      email = DepartmentEmail.find(params[:id])

      present email, with: API::V1::DepartmentEmailEntity
    end

    desc 'Create a department email'
    params do
      requires :address, type: String
      requires :uuids, type: Array
      requires :first_name, type: String
      requires :last_name, type: String
      optional :department, type: String
      optional :title, type: String
      optional :privacy, type: Boolean
    end
    post do
      GoogleAccount.new(params[:address]).create! params.slice(:first_name, :last_name, :department, :title, :privacy)
      email = DepartmentEmail.create! address: params[:address], uuids: params[:uuids]

      present email, with: API::V1::DepartmentEmailEntity
    end

    desc 'Update a department email'
    params do
      optional :address, type: String
      optional :uuids, type: Array
      optional :first_name, type: String
      optional :last_name, type: String
      optional :department, type: String
      optional :title, type: String
      optional :privacy, type: Boolean
    end
    put ':department_email_id' do
      email = DepartmentEmail.find(params[:department_email_id])

      model_args = params.slice(:address, :uuids).to_hash
      email.update! model_args if model_args.any?

      api_args = params.slice(:first_name, :last_name, :department, :title, :privacy)
      GoogleAccount.new(email.address).update! api_args if api_args.any?

      present email, with: API::V1::DepartmentEmailEntity
    end
  end
end
