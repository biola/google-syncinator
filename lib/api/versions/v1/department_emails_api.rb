# Version 1 of the department emails Grape API
class API::V1::DepartmentEmailsAPI < Grape::API
  include Grape::Kaminari

  resource :department_emails do
    desc 'Gets an individual department email'
    params do
      requires :id, type: String
    end
    get ':id' do
      present_email DepartmentEmail.find(params[:id])
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

      present_email email
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

      present_email email
    end
  end

  helpers do
    def present_email(department_email)
      google_email = GoogleAccount.new(department_email.address)

      attribs = google_email.to_hash
      attribs.merge! department_email.attributes
      attribs.merge! id: department_email.id # attributes uses _id
      attribs.merge! deprovision_schedules: department_email.deprovision_schedules
      attribs.merge! exclusions: department_email.exclusions
      attribs.merge! alias_emails: department_email.alias_emails
      email = OpenStruct.new(attribs)

      present email, with: API::V1::DepartmentEmailEntity
    end
  end
end
