# Version 1 of the Exclusions Grape API
class API::V1::ExclusionsAPI < Grape::API
  resource :exclusions do
    before do
      @email = AccountEmail.find_by(id: params[:email_id])
    end

    desc 'Create an exclusion'
    params do
      requires :creator_uuid, type: String
      requires :starts_at, type: DateTime
      optional :ends_at, type: DateTime
      optional :reason, type: String
    end
    post do
      args = [:creator_uuid, :starts_at, :ends_at, :reason].each_with_object({}) do |key, hash|
        hash[key] = params[key]
      end
      exclusion = @email.exclusions.create args

      present exclusion, with: API::V1::ExclusionEntity
    end

    desc 'Delete an exclusion'
    delete ':exclusion_id' do
      exclusion = @email.exclusions.find(params[:exclusion_id])

      exclusion.destroy!

      present exclusion, with: API::V1::ExclusionEntity
    end
  end
end
