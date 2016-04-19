# Helper module for HMAC authentication with Grape
module AuthenticationHelpers
  # Simple wrapper around Rack::Request
  # @return [Rack::Request]
  def rack_request
    Rack::Request.new(@env)
  end

  # Get's the currently authenticated client
  # @return [Client]
  def current_client
    access_id = ApiAuth.access_id(rack_request)
    Client.where(access_id: access_id).first
  end

  # Is the request using a valid access_id/secret_key combo?
  def authentic?
    secret_key = current_client.try(:secret_key)

    ApiAuth.authentic? rack_request, secret_key
  end

  # Authenticate the client or raise an error
  def authenticate!
     unauthorized! unless authentic?
  end

  # Raise an 401 unauthorized error
  def unauthorized!
    error!('401 Unauthorized', 401)
  end
end
