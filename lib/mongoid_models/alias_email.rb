class AliasEmail < UniversityEmail
  # @!attribute account_email
  #   @return [AccountEmail]
  # @!method account_email=(account_email)
  #   @param account_email [AccountEmail]
  #   @return [AccountEmail]
  belongs_to :account_email

  before_create :set_state

  protected

  def set_state
    self.state = account_email.state
  end
end
