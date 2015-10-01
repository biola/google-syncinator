# UniversityEmail Grape entity. Used to serialize UniversityEmail objects to JSON.
# @note UniversityEmail is inherited by other classes so it has to adapt depending
#   on which class is being serialized.
class API::V1::UniversityEmailEntity < Grape::Entity
  expose :_type
  expose(:id) { |email| email.id.to_s }
  expose :address
  expose :state

  # For AliasEmail
  expose(:account_email_id, if: -> (inst, _) { inst.is_a? AliasEmail }) { |email| email.account_email.id.to_s }

  # For PersonEmail
  expose :uuid, if: -> (inst, _) { inst.is_a? PersonEmail }
  expose :deprovision_schedules, using: API::V1::DeprovisionScheduleEntity, if: -> (inst, _) { inst.is_a? PersonEmail }
  expose :exclusions, using: API::V1::ExclusionEntity, if: -> (inst, _) { inst.is_a? PersonEmail }
end
