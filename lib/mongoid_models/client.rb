# Stores credentials for API clients
class Client
  require 'api_auth'

  include Mongoid::Document
  include Mongoid::Timestamps

  # @!attribute name
  #   A name for the client. Can be anything.
  #   @return [String] Client name
  # @!method name=(name)
  #   @param name [String] Client name
  #   @return [String]
  field :name, type: String

  # @!attribute [r] slug
  #   @note Automatically generated based off the name
  #   @return [String] Client slug
  field :slug, type: String

  # @!attribute [r] access_id
  #   Functions as the client username, basically
  #   @note Automatically generated
  #   @return [String] Client access ID
  field :access_id, type: Integer

  # @!attribute [r] secret_key
  #   @note Automatically generated
  #   @return [String] Client secret key
  field :secret_key, type: String

  # @!attribute active
  #   Set to false to disable this client.
  #   @return [Boolean]
  # @!method active=(active)
  #   @param active [Boolean]
  #   @return [Boolean]
  field :active, type: Boolean, default: true

  attr_readonly :slug, :access_id, :secret_key

  validates :name, :slug, :access_id, :secret_key, presence: true
  validates :name, :slug, :access_id, :secret_key, uniqueness: true

  before_validation :set_default_slug, :set_access_id, :set_secret_key, on: :create

  # The name of the client
  # @return [String]
  def to_s
    name
  end

  private

  # The maximum size of a Fixnum in Ruby
  FIXNUM_MAX = (2**(0.size * 8 -2) -1)

  def set_default_slug
    self.slug ||= name.parameterize
  end

  def set_access_id
    self.access_id ||= rand(FIXNUM_MAX)
  end

  def set_secret_key
    self.secret_key ||= ApiAuth.generate_secret_key
  end
end
