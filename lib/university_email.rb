class UniversityEmail
  include Mongoid::Document
  include Mongoid::Timestamps

  embeds_many :deprovision_schedules

  field :uuid, type: String
  field :address, type: String
  field :primary, type: Boolean, default: true
  field :state, type: Symbol, default: :active
  # TODO: probably want a reusable_on field

  validates :uuid, :address, :primary, :state, presence: true
  validates :address, uniqueness: {scope: :uuid}
  validates :state, inclusion: {in: [:active, :suspended, :deleted]}

  def active?() state == :active; end
  def suspended?() state == :suspended; end
  def deleted?() state == :deleted; end

  # Get the date when the email will be either suspended or deleted
  def disable_date
    deprovision_schedules.where(:action.in => [:suspend, :delete]).asc(:scheduled_for).first.try(:scheduled_for)
  end

  def being_deprovisioned?
    deprovision_schedules.any?(&:pending?)
  end

  def cancel_deprovisioning!
    deprovision_schedules.where(completed_at: nil).each do |schedule|
      Sidekiq::Status.cancel schedule.job_id
      schedule.update canceled: true
    end
  end

  def self.current(address)
    UniversityEmail.where(address: address, :state.ne => :deleted).first
  end

  def self.active?(uuid)
    where(uuid: uuid, primary: :true, state: :active).any?
  end

  def self.available?(address)
    # TODO: Check for deleted but not yet reusable addresses.
    where(address: address).all? { |ue| ue.deleted? }
  end

  def self.find_reprovisionable(uuid)
    # This is an N+1 query but we're probably almost never talking about more than 1 result, so I'm not worried about it
    where(uuid: uuid, primary: true, :state.in => [:suspended, :deleted]).to_a.find do |email|
      where(address: email.address, state: :active).none?
    end
  end
end