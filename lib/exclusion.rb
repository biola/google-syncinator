class Exclusion
  include Mongoid::Document
  include Mongoid::Timestamps

  embedded_in :university_email

  field :creator_uuid, type: String
  field :starts_at, type: DateTime
  field :ends_at, type: DateTime
  field :reason, type: String

  # REVIEW: should we require a reason
  validates :creator_uuid, :starts_at, presence: true

  validate do
    if ends_at.present? && ends_at <= starts_at
      errors.add(:ends_at, 'must be after starts at')
    end
  end
end
