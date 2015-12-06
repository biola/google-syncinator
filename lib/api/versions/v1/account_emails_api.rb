# Version 1 of the account emails Grape API
# @note includes PersonEmails and DepartmentEmails
class API::V1::AccountEmailsAPI < Grape::API
  resource :account_emails do
    desc 'Search account emails'
    params do
      requires :q, type: String
    end
    get do
      emails = AccountEmail.where(address: Regexp.new(params[:q], Regexp::IGNORECASE))
      present emails, with: API::V1::AccountEmailEntity
    end

    desc 'Gets an individual account email'
    params do
      requires :id, type: String
    end
    get ':id' do
      present AccountEmail.find(params[:id]), with: API::V1::AccountEmailEntity
    end
  end
end
