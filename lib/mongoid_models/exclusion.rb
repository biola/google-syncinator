# Excludes emails from being deprovisioned
# @note emails that are excluded will be left in their current state, which isn't necessarily active
class Exclusion
  include Mongoid::Document
  include Mongoid::Timestamps

  # @!attribute university_email
  # @return [UniversityEmail]
  # @!method university_email=(university_email)
  #   @param university_email [UniversityEmail]
  #   @return [UniversityEmail]
  embedded_in :university_email

  # @!attribute creator_uuid
  #   @return [String] The UUID of the person who created the exception
  # @!method creator_uuid=(creator_uuid)
  #   @param creator_uuid [String] The UUID of the person who created the exception
  #   @return [String]
  field :creator_uuid, type: String

  # @!attribute starts_at
  #   @return [DateTime] The time when the exclusion will/did begin
  # @!method starts_at=(starts_at)
  #   @param starts_at [DateTime] The time when the exclusion will/did begin
  #   @return [DateTime]
  field :starts_at, type: DateTime

  # @!attribute ends_at
  #   @return [DateTime] The time when the exclusion will/did end
  # @!method ends_at=(ends_at)
  #   @param ends_at [DateTime] The time when the exclusion will/did end
  #   @return [DateTime]
  field :ends_at, type: DateTime

  # @!attribute reason
  #   @return [String] The reason that the exclusion was made
  # @!method reason=(reason)
  #   @param reason [String] The reason that the exclusion was made
  #   @return [String]
  field :reason, type: String

  # REVIEW: should we require a reason
  validates :creator_uuid, :starts_at, presence: true

  validate do
    if ends_at.present? && ends_at <= starts_at
      errors.add(:ends_at, 'must be after starts at')
    end
  end
end
