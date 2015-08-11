# Stores a record of all past and present email addresses, who they belonged to
#   and when and how they were derpovisioned
class UniversityEmail
  include Mongoid::Document
  include Mongoid::Timestamps

  # The valid states an email can be in
  STATES = [:active, :suspended, :deleted]

  # @!attribute deprovision_schedules
  #   @return [Array<DeprovisionSchedule>]
  # @!method deprovision_schedules=(deprovision_schedules)
  #   @param deprovision_schedules [Array<DeprovisionSchedule>]
  #   @return [Array<DeprovisionSchedule>]
  embeds_many :deprovision_schedules

  # @!attribute exclusions
  #   @return [Array<Exclusion>]
  # @!method exclusions=(exclusions)
  #   @param exclusions [Array<Exclusion>]
  #   @return [Array<Exclusion>]
  embeds_many :exclusions

  # @!attribute uuid
  #   @return [String] the Trogdir UUID of the person who owns the email
  # @!method uuid=(uuid)
  #   @param uuid [String] the Trogdir UUID of the person who owns the email
  #   @return [String]
  field :uuid, type: String

  # @!attribute address
  #   @return [String] the full email address
  # @!method address=(address)
  #   @param address [String] the full email address
  #   @return [String]
  field :address, type: String

  # @!attribute primary
  #   @return [Boolean] Whether or not this is the person's primary address
  # @!method primary=(primary)
  #   @param primary [Boolean] Whether or not this is the person's primary address
  #   @return [Boolean]
  field :primary, type: Boolean, default: true

  # @!attribute state
  #   @return [Symbol] the current state of the email
  #   @note this is automatically set when deprovision schedules are completed
  #   @see DeprovisionSchedule
  # @!method state=(state)
  #   @param state [Symbol] the current state of the email
  #   @return [Symbol]
  #   @see STATES
  field :state, type: Symbol, default: :active

  validates :uuid, :address, :primary, :state, presence: true
  validates :address, uniqueness: {scope: :uuid}
  validates :state, inclusion: {in: STATES}

  # Is the state currently active?
  # @see #state
  def active?() state == :active; end

  # Is the state currently suspended?
  # @see #state
  def suspended?() state == :suspended; end

  # Is the state currently deleted?
  # @see #state
  def deleted?() state == :deleted; end

  # Get the date when the email will be either suspended or deleted
  # @return [DateTime] when a suspend or delete action is scheduled
  # @return [nil] when there is no suspend or delete action scheduled
  def disable_date
    deprovision_schedules.where(:action.in => [:suspend, :delete]).asc(:scheduled_for).first.try(:scheduled_for)
  end

  # Whether or not the email address was created recently enough to be considered protected
  # @note Recently created emails are protected from deprovisioning for a certain amount of time
  def protected?
    created_at > (Time.now - Settings.deprovisioning.protect_for)
  end

  # The end date of the period when the account is protected from deprovisioning
  # @return [Time]
  def protected_until
    created_at + Settings.deprovisioning.protect_for
  end

  # Does an currently active exclusion record exist?
  def excluded?
    exclusions.any? do |exclusion|
      exclusion.starts_at.past? && (exclusion.ends_at.nil? || exclusion.ends_at.future?)
    end
  end

  # Is the email currently scheduled for deprovisioning
  def being_deprovisioned?
    deprovision_schedules.any?(&:pending?)
  end

  # Cancel the pending deprovisions for this email
  # @return [Array<DeprovisionSchedule>]
  def cancel_deprovisioning!
    deprovision_schedules.where(completed_at: nil).each { |schedule|
      Sidekiq::Status.cancel schedule.job_id
      schedule.update canceled: true
    }.to_a
  end

  # The UUID and address and a string
  # @return [String]
  # @example university_email.to_s #=> "00000000-0000-0000-0000-000000000000/bob.dole@biola.edu"
  def to_s
    "#{uuid}/#{address}"
  end

  # Get the current active {UniversityEmail} for an address, if any
  # @note There should only ever be one active record for an address
  # @param address [String] the full email address to find with
  # @return [UniversityEmail] when found
  # @return [nil] when not found
  def self.current(address)
    UniversityEmail.where(address: address, :state.ne => :deleted).first
  end

  # Does the person have an active {UniversityEmail}?
  # @param uuid [String] the Trogdir UUID of the person
  def self.active?(uuid)
    where(uuid: uuid, primary: :true, state: :active).any?
  end

  # Is the given email address available or taken?
  # @note non-existant and deleted emails are considered available, suspended emails are not
  # @param address [String] the email address to check the availability of
  def self.available?(address)
    where(address: address).all? { |ue| ue.deleted? }
  end

  # Find any suspended or deleted email for a user so that it can be re-activated
  # @param uuid [String] The Trogdir UUID of the person
  # @return [UniversityEmail]
  def self.find_reprovisionable(uuid)
    # This is an N+1 query but we're probably almost never talking about more than 1 result, so I'm not worried about it
    where(uuid: uuid, primary: true, :state.in => [:suspended, :deleted]).to_a.find do |email|
      where(address: email.address, state: :active).none?
    end
  end
end
