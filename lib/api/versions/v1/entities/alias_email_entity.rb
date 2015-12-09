# AliasEmail Grape entity. Used to serialize AliasEmail objects to JSON.
class API::V1::AliasEmailEntity < Grape::Entity
  expose(:id) { |email| email.id.to_s }
  expose(:account_email_id) { |email| email.account_email.id.to_s }
  expose :address
  expose :state
  expose :deprovision_schedules, using: API::V1::DeprovisionScheduleEntity
end
