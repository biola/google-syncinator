# Version 1 of the Grape API
class API::V1 < Grape::API
  require './lib/api/versions/v1/entities/university_email_entity'

  include Grape::Kaminari

  version 'v1', using: :path, vendor: :google_syncinator

  resource :emails do
    desc 'Gets a list of email objects with pagination and optional search params'
    params do
      optional :q, type: String
    end
    paginate
    get do
      emails = if params[:q].present?
        regex = Regexp.new(params[:q].gsub(/\s/, '.*'), Regexp::IGNORECASE)
        UniversityEmail.where(address: regex)
      else
        UniversityEmail.asc(:address)
      end

      present paginate(emails), with: UniversityEmailEntity
    end

    desc 'Gets an individual email'
    params do
      requires :id, type: String
    end
    get ':id' do
      email = UniversityEmail.find(params[:id])

      present email, with: UniversityEmailEntity
    end

    desc 'Create an email'
    params do
      requires :uuid, type: String
      requires :address, type: String
      optional :primary, type: Boolean, default: true
    end
    post do
      email = UniversityEmail.create(uuid: params[:uuid], address: params[:address], primary: params[:primary])

      present email, with: UniversityEmailEntity
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
      email.update primary: params[:primary]
      present email, with: UniversityEmailEntity
    end
  end
end
