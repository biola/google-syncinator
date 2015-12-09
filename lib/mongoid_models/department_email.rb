# Represents an email address for a department that is tied to a Google Apps account and one or more people in Trogdir
class DepartmentEmail < AccountEmail
  # @!attribute uuids
  #   @return [String] the Trogdir UUIDs of the people who own the email
  # @!method uuids=(uuids)
  #   @param uuids [Array<String>] the Trogdir UUIDs of the people who own the email
  #   @return [Array<String>]
  field :uuids, type: Array

  validates :uuids, presence: true

  # Email addresses who should recieve notifications about this account
  # @return [Array<AccountEmail>] email addresses
  def notification_recipients
    [self] + uuids.map { |uuid| PersonEmail.find_by(uuid: uuid) }
  end

  # Whether or not this record should be synced to Trogdir
  # @return [Boolean]
  def sync_to_trogdir?
    false
  end

  # Whether or not this record should be synced to the legacy email table
  # @return [Boolean]
  def sync_to_legacy_email_table?
    false
  end

  # The address as a string
  # @return [String]
  # @example department_email.to_s #=> "bob.dole@biola.edu"
  def to_s
    address
  end
end
