# Version 1 of the Emails Grape API
class API::V1::EmailsAPI < Grape::API
  include Grape::Kaminari

  resource :emails do
    desc 'Gets a list of email objects with pagination and optional search params'
    params do
      optional :q, type: String
      optional :state, type: String
      optional :pending, type: String
      optional :_type, type: String
      optional :vfe, type: Boolean
    end
    paginate
    get do
      ors = []
      ands = []

      if params[:q].present?
        ors << {address: Regexp.new(params[:q].gsub(/\s/, '.*'), Regexp::IGNORECASE)}
        ors << {uuid: params[:q]}
      end

      if params[:state].present?
        ands << {state: params[:state]}
      end

      if params[:pending].present?
        ands << {:'deprovision_schedules.scheduled_for'.ne => nil, 'deprovision_schedules.completed_at' => nil, 'deprovision_schedules.canceled' => nil}
      end

      if params[:_type].present?
        ands << {_type: params[:_type]}
      end

      if params[:vfe].present?
        ands << {vfe: params[:vfe]}
      end

      emails = if ors.any? || ands.any?
        UniversityEmail.or(*ors).and(*ands)
      else
        UniversityEmail.asc(:address)
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
