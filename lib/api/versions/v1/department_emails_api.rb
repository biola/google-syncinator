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
      optional :first_name, type: String
      optional :last_name, type: String
      optional :department, type: String
      optional :title, type: String
      optional :privacy, type: Boolean
    end
    post do
      GoogleAccount.new(params[:address]).create! params[:first_name], params[:last_name], params[:department], params[:title], params[:privacy]
      email = DepartmentEmail.create! address: params[:address], uuids: params[:uuids]

      present email, with: API::V1::DepartmentEmailEntity
    end
  end
end
