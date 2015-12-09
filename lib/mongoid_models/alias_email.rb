# Represents an alias email address tied to an account email
class AliasEmail < UniversityEmail
  # @!attribute account_email
  #   @return [AccountEmail]
  # @!method account_email=(account_email)
  #   @param account_email [AccountEmail]
  #   @return [AccountEmail]
  belongs_to :account_email

  before_create :set_state

  delegate :uuid, to: :account_email

  # Whether or not this record should be synced to Trogdir
  # @return [Boolean]
  def sync_to_trogdir?
    false
  end

  # Whether or not this record should be synced to the legacy email table
  # @return [Boolean]
  def sync_to_legacy_email_table?
    account_email.is_a?(PersonEmail)
  end

  protected

  # Default the state to the state of the associated account_email
  # @note an ailas' state should always be the same as the associated account_email
  def set_state
    self.state = account_email.state
  end
end
