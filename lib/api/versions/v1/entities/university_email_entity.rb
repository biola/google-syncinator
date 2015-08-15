# UniversityEmail Grape entity. Used to serialize UniversityEmail objects to JSON.
class API::V1::UniversityEmailEntity < Grape::Entity
  expose(:id) { |email| email.id.to_s }
  expose :uuid
  expose :address
  expose :primary
  expose :state
end
