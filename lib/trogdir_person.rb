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

  private

  def hash
    @hash ||= (
      response = Trogdir::APIClient::People.new.show(uuid: uuid).perform
      raise TrogdirAPIError, response.parse['error'] unless response.success?
      response.parse
    )
  end
end
