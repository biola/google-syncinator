# Version 1 of the Emails Grape API
class API::V1::EmailsAPI < Grape::API
  include Grape::Kaminari

  resource :emails do
    desc 'Gets a list of email objects with pagination and optional search params'
    params do
      optional :q, type: String
    end
    paginate
    get do
      emails = if params[:q].present?
        regex = Regexp.new(params[:q].gsub(/\s/, '.*'), Regexp::IGNORECASE)
        UniversityEmail.or({address: regex}, {uuid: params[:q]})
      else
        UniversityEmail.asc(:address).asc(:address)
      end

      present paginate(emails), with: API::V1::UniversityEmailEntity
    end

    desc 'Gets an individual email'
    params do
      requires :id, type: String
    end
    get ':id' do
      email = UniversityEmail.find(params[:id])

      present email, with: API::V1::UniversityEmailEntity
    end

    desc 'Create an email'
    params do
      requires :uuid, type: String
      requires :address, type: String
      optional :primary, type: Boolean, default: true
    end
    post do
      # NOTE: We need the email object back so don't preform asynchronously here
      email = Workers::CreateEmail.new.perform(params[:uuid], params[:address], params[:primary])

      present email, with: API::V1::UniversityEmailEntity
    end

    desc 'Update an email'
    params do
      requires :id, type: String
      # NOTE: eventually primary shouldn't be required, but since it's the only
      #   thing that makes sense to update now, might as well require it.
      requires :primary, type: Boolean
    end
    put ':id' do
      email = UniversityEmail.find(params[:id])
      email.update! primary: params[:primary]
      # TODO: handle updating records in Google, Trogdir and the legacy email table
      present email, with: API::V1::UniversityEmailEntity
    end
  end
end
