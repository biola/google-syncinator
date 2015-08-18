# Exclusion Grape entity. Used to serialize Exclusion objects to JSON.
class ExclusionEntity < Grape::Entity
  expose :creator_uuid
  expose :starts_at
  expose :ends_at
  expose :reason
end
