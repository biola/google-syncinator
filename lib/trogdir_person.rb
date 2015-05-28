class TrogdirPerson
  class TrogdirAPIError < StandardError; end
  attr_reader :uuid

  def initialize(uuid)
    @uuid = uuid
  end

  %w(first_name last_name department title privacy).each do |m|
    define_method(m) do
      hash[m]
    end
  end

  define_method("biola_id") do
    Array(hash['ids']).find { |id| id['type'] == 'biola_id' }['identifier']
  end

  def first_or_preferred_name
    hash['preferred_name'] || hash['first_name']
  end

  private

  def hash
    @hash ||= (
      response = Trogdir::APIClient::People.new.show(uuid: uuid).perform
      raise TrogdirAPIError, response.parse['error'] unless response.success?
      response.parse
    )
  end
end
