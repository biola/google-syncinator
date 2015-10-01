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
  end
end
