# Represents an email address for a department that is tied to a Google Apps account and one or more people in Trogdir
class DepartmentEmail < AccountEmail
  # @!attribute uuids
  #   @return [String] the Trogdir UUIDs of the people who own the email
  # @!method uuids=(uuids)
  #   @param uuids [Array<String>] the Trogdir UUIDs of the people who own the email
  #   @return [Array<String>]
  field :uuids, type: Array

  validates :uuids, presence: true

  # The address as a string
  # @return [String]
  # @example account_email.to_s #=> "bob.dole@biola.edu"
  def to_s
    address
  end
end
