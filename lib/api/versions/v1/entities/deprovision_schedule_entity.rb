# DeprovisionSchedule Grape entity. Used to serialize DeprovisionSchedule objects to JSON.
class API::V1::DeprovisionScheduleEntity < Grape::Entity
  expose(:id) { |schedule| schedule.id.to_s }
  expose(:email_id) { |schedule| schedule.account_email.id.to_s }
  expose :action
  expose :reason
  expose :scheduled_for
  expose :completed_at
  expose :canceled
end
