class DeprovisionSchedule
  include Mongoid::Document
  include Mongoid::Timestamps

  embedded_in :university_email

  field :action, type: Symbol
  field :reason, type: String
  field :scheduled_for, type: DateTime
  field :completed_at, type: DateTime
  field :canceled, type: Boolean
  field :job_id, type: String

  validates :action, presence: true
  validates :scheduled_for, presence: true, unless: :completed_at?
  validates :completed_at, presence: true, unless: :scheduled_for?
  # TODO: do we need a "check again in 1 month" action
  validates :action, inclusion: {in: [:notify_of_inactivity, :notify_of_closure, :suspend, :delete, :activate]}
end
