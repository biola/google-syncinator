class UniversityEmail
  include Mongoid::Document
  include Mongoid::Timestamps

  embeds_many :deprovision_schedules

  field :uuid, type: String
  field :address, type: String
  field :primary, type: Boolean, default: true
  field :state, type: Symbol, default: :active

  validates :uuid, :address, :primary, :state, presence: true
  validates :address, uniqueness: {scope: :uuid}
  validates :state, inclusion: {in: [:active, :suspended, :deleted]}
end
