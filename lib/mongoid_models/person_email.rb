# Represents a primary email address tied to a Google Apps account and a person in Trogdir
class PersonEmail < AccountEmail
  # @!attribute uuid
  #   @return [String] the Trogdir UUID of the person who owns the email
  # @!method uuid=(uuid)
  #   @param uuid [String] the Trogdir UUID of the person who owns the email
  #   @return [String]
  field :uuid, type: String

  validates :uuid, presence: true
  validates :address, uniqueness: {scope: :uuid}

  # Does the person have an active {UniversityEmail}?
  # @param uuid [String] the Trogdir UUID of the person
  def self.active?(uuid)
    where(uuid: uuid, state: :active).any?
  end

  # Find any suspended or deleted email for a user so that it can be re-activated
  # @param uuid [String] The Trogdir UUID of the person
  # @return [AccountEmail]
  def self.find_reprovisionable(uuid)
    # This is an N+1 query but we're probably almost never talking about more than 1 result, so I'm not worried about it
    where(uuid: uuid, :state.in => [:suspended, :deleted]).to_a.find do |email|
      where(address: email.address, state: :active).none?
    end
  end

  # The UUID and address as a string
  # @return [String]
  # @example account_email.to_s #=> "00000000-0000-0000-0000-000000000000/bob.dole@biola.edu"
  def to_s
    "#{uuid}/#{address}"
  end
end
