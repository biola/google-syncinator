# DeprovisionSchedule Grape entity. Used to serialize DeprovisionSchedule objects to JSON.
class DeprovisionScheduleEntity < Grape::Entity
  expose :action
  expose :reason
  expose :scheduled_for
  expose :completed_at
  expose :canceled
end
