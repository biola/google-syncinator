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

  # @!attribute address
  #   @return [String] the full email address
  # @!method address=(address)
  #   @param address [String] the full email address
  #   @return [String]
  field :address, type: String

  # @!attribute state
  #   @return [Symbol] the current state of the email
  #   @note this is automatically set when deprovision schedules are completed
  #   @see DeprovisionSchedule
  # @!method state=(state)
  #   @param state [Symbol] the current state of the email
  #   @return [Symbol]
  #   @see STATES
  field :state, type: Symbol, default: :active

  validates :address, :state, presence: true
  validates :state, inclusion: {in: STATES}

  validate do
    if state != :deleted && UniversityEmail.where(address: address, :state.ne => :deleted, :id.ne => id).any?
      errors.add(:address, 'is already being used')
    end
  end

  # Is the state currently active?
  # @see #state
  def active?() state == :active; end

  # Is the state currently suspended?
  # @see #state
  def suspended?() state == :suspended; end

  # Is the state currently deleted?
  # @see #state
  def deleted?() state == :deleted; end

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

  # Get the date when the email will be either suspended or deleted
  # @return [DateTime] when a suspend or delete action is scheduled
  # @return [nil] when there is no suspend or delete action scheduled
  def disable_date
    deprovision_schedules.where(:action.in => [:suspend, :delete]).asc(:scheduled_for).first.try(:scheduled_for)
  end

  # Is the email currently scheduled for deprovisioning
  def being_deprovisioned?
    deprovision_schedules.any?(&:pending?)
  end

  # Cancel the pending deprovisions for this email
  # @return [Array<String>] sidekiq job IDs
  def cancel_deprovisioning!
    deprovision_schedules.where(completed_at: nil).each(&:cancel!).to_a
  end

  # The address as a string
  # @return [String]
  # @example university_email.to_s #=> "bob.dole@biola.edu"
  def to_s
    address.to_s
  end

  # Whether or not this record should be synced to Trogdir
  # @return [Boolean]
  def sync_to_trogdir?
    raise NotImplementedError, 'This method should be overridden in child clasess'
  end

  # Whether or not this record should be synced to the legacy email table
  # @return [Boolean]
  def sync_to_legacy_email_table?
    raise NotImplementedError, 'This method should be overridden in child clasess'
  end

  # Get the current active {UniversityEmail} for an address, if any
  # @note There should only ever be one active record for an address
  # @param address [String] the full email address to find with
  # @return [UniversityEmail] when found
  # @return [nil] when not found
  def self.current(address)
    where(address: address, :state.ne => :deleted).first
  end

  # Is the given email address available or taken?
  # @note non-existant and deleted emails are considered available, suspended emails are not
  # @param address [String] the email address to check the availability of
  def self.available?(address)
    where(address: address).all? { |ue| ue.deleted? }
  end
end
