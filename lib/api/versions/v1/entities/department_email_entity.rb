# DepartmentEmail Grape entity. Used to serialize DepartmentEmail objects to JSON.
class API::V1::DepartmentEmailEntity < Grape::Entity
  expose(:id) { |email| email.id.to_s }
  expose :address
  expose :uuids
  expose :first_name
  expose :last_name
  expose :department
  expose :title
  expose :privacy
  expose :org_unit_path
  expose :state
  expose :deprovision_schedules, using: API::V1::DeprovisionScheduleEntity
  expose :exclusions, using: API::V1::ExclusionEntity
  expose :alias_emails, using: API::V1::AliasEmailEntity
end
