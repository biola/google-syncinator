# PersonEmail Grape entity. Used to serialize PersonEmail objects to JSON.
class API::V1::PersonEmailEntity < Grape::Entity
  expose(:id) { |email| email.id.to_s }
  expose :uuid
  expose :address
  expose :state
  expose :deprovision_schedules, using: API::V1::DeprovisionScheduleEntity
  expose :exclusions, using: API::V1::ExclusionEntity
  expose :alias_emails, using: API::V1::AliasEmailEntity
end
