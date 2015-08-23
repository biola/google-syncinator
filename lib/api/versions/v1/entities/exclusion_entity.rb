# Exclusion Grape entity. Used to serialize Exclusion objects to JSON.
class API::V1::ExclusionEntity < Grape::Entity
  expose(:id) { |exclusion| exclusion.id.to_s }
  expose :creator_uuid
  expose :starts_at
  expose :ends_at
  expose :reason
end
