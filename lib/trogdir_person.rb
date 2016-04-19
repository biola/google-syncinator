# A simple wrapper object for a person record in Trogdir
class TrogdirPerson
  # Exception for when an error occurs with Trogdir
  class TrogdirAPIError < StandardError; end

  # The UUID of the person
  #   @return [String]
  attr_reader :uuid

  # Initialize a new TrogdirPerson object with their UUID
  def initialize(uuid)
    @uuid = uuid
  end

  # @!attribute [r] first_name
  #   @return [String]

  # @!attribute [r] last_name
  #   @return [String]

  # @!attribute [r] department
  #   @return [String]
  #   @return [nil] when no department exists

  # @!attribute [r] title
  #   @return [String]
  #   @return [nil] when no title exists

  # @!attribute [r] privacy
  #   @return [Boolean]

  # @!attribute [r] affiliations
  #   @return [Array<String>]
  %w(first_name last_name department title privacy affiliations).each do |m|
    define_method(m) do
      hash[m]
    end
  end

  # The Biola ID of the person
  # @return [String]
  def biola_id
    Array(hash['ids']).find { |id| id['type'] == 'biola_id' }.try(:[], 'identifier')
  end

  # The persons preferred name or first name if no preferred name exists
  # @return [String]
  def first_or_preferred_name
    hash['preferred_name'] || hash['first_name']
  end

  private

  # The person hash from Trogdir
  # @return [Hash]
  def hash
    @hash ||= (
      response = Trogdir::APIClient::People.new.show(uuid: uuid).perform
      raise TrogdirAPIError, response.parse['error'] unless response.success?
      response.parse
    )
  end
end
