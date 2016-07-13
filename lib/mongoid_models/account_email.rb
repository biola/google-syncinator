# Represents a primary email address tied to a Google Apps account
class AccountEmail < UniversityEmail
  # @!attribute exclusions
  #   @return [Array<Exclusion>]
  # @!method exclusions=(exclusions)
  #   @param exclusions [Array<Exclusion>]
  #   @return [Array<Exclusion>]
  embeds_many :exclusions

  # @!attribute alias_emails
  #   @return [Array<AliasEmail>]
  # @!method alias_emails=(alias_emails)
  #   @param alias_emails [Array<AliasEmail>]
  #   @return [Array<AliasEmail>]
  has_many :alias_emails, dependent: :destroy

  # @!attribute vfe
  #   @return [Boolean] whether or not the email has been vaulted in Google apps
  # @!method vfe=(vfe)
  #   @param vfe [Boolean]
  #   @return [Boolean]
  field :vfe, type: Boolean, default: false


  after_save :update_alias_state

  # Email addresses who should recieve notifications about this account
  # @return [Array<String>] email addresses
  def notification_recipients
    raise NotImplementedError, 'This method should be overridden in child classes'
  end

  # Does an currently active exclusion record exist?
  def excluded?
    exclusions.any? do |exclusion|
      exclusion.starts_at.past? && (exclusion.ends_at.nil? || exclusion.ends_at.future?)
    end
  end

  protected

  def update_alias_state
    if state_changed?
      AliasEmail.where(account_email: self, :state.ne => :deleted).update_all state: state
    end
  end
end
