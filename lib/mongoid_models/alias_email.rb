# Represents an alias email address tied to an account email
class AliasEmail < UniversityEmail
  # @!attribute account_email
  #   @return [AccountEmail]
  # @!method account_email=(account_email)
  #   @param account_email [AccountEmail]
  #   @return [AccountEmail]
  belongs_to :account_email

  before_create :set_state

  protected

  # Default the state to the state of the associated account_email
  # @note an ailas' state should always be the same as the associated account_email
  def set_state
    self.state = account_email.state
  end
end
