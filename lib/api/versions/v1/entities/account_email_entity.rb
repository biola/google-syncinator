# AccountEmail Grape entity. Used to serialize AccountEmail objects to JSON.
class API::V1::AccountEmailEntity < Grape::Entity
  expose(:id) { |email| email.id.to_s }
  expose :address
  expose :state
  expose :deprovision_schedules, using: API::V1::DeprovisionScheduleEntity
  expose :exclusions, using: API::V1::ExclusionEntity
end
