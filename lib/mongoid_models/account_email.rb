# Represents a primary email address tied to a Google Apps account
class AccountEmail < UniversityEmail
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

  # @!attribute alias_emails
  #   @return [Array<AliasEmail>]
  # @!method alias_emails=(alias_emails)
  #   @param alias_emails [Array<AliasEmail>]
  #   @return [Array<AliasEmail>]
  has_many :alias_emails, dependent: :destroy


  after_save :update_alias_state

  # Email addresses who should recieve notifications about this account
  # @return [Array<String>] email addresses
  def notification_recipients
    raise NotImplementedError, 'This method should be overridden in child clasess'
  end

  # Whether or not this record should be synced to Trogdir
  # @return [Boolean]
  def self.sync_to_trogdir?
    raise NotImplementedError, 'This method should be overridden in child clasess'
  end

  # Whether or not this record should be synced to the legacy email table
  # @return [Boolean]
  def self.sync_to_legacy_email_table?
    raise NotImplementedError, 'This method should be overridden in child clasess'
  end

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
  # @return [Array<String>] sidekiq job IDs
  def cancel_deprovisioning!
    deprovision_schedules.where(completed_at: nil).each(&:cancel!).to_a
  end

  protected

  def update_alias_state
    if state_changed?
      AliasEmail.where(account_email: self).update_all state: state
    end
  end
end
