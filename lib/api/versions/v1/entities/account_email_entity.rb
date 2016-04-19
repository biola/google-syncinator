# AccountEmail Grape entity. Used to serialize AccountEmail objects to JSON.
class API::V1::AccountEmailEntity < Grape::Entity
  expose(:id) { |email| email.id.to_s }
  expose :_type
  expose :address
  expose :state
  expose :deprovision_schedules, using: API::V1::DeprovisionScheduleEntity
  expose :exclusions, using: API::V1::ExclusionEntity

  # For PersonEmails
  expose(:uuid, if: -> (inst, _) { inst.is_a? PersonEmail }) { |email| email.uuid }

  # For DepartmentEmails
  expose(:uuids, if: -> (inst, _) { inst.is_a? DepartmentEmail }) { |email| email.uuids }
end
