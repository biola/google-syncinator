# Stores a record of all past and present email addresses, who they belonged to
#   and when and how they were derpovisioned
class UniversityEmail
  include Mongoid::Document
  include Mongoid::Timestamps

  # The valid states an email can be in
  STATES = [:active, :suspended, :deleted]

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

  # The address as a string
  # @return [String]
  # @example university_email.to_s #=> "bob.dole@biola.edu"
  def to_s
    address.to_s
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
