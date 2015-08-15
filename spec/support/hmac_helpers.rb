module HMACHelpers
  def app
    API
  end

  [:get, :post, :put, :delete].each do |verb|
    define_method("signed_#{verb}") { |url, params = nil, client = nil| signed_request(verb, url, params, client) }
  end

  def signed_request(method, url, params = nil, client = nil)
    client ||= Client.create name: 'For Rspec'
    env = Rack::MockRequest.env_for(url, method: method, params: params)

    req = Rack::Request.new(env).tap do |r|
      ApiAuth.sign! r, client.access_id, client.secret_key
    end

    Rack::MockResponse.new *app.call(req.env)
  end
end
