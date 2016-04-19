# Parent Grape API class
# @note all active API version classes should be mounted here
class API < Grape::API
  require 'rack/turnout'
  require './lib/api/helpers/authentication_helpers'
  require './lib/api/versions/v1'

  include Grape::Kaminari

  format :json
  rescue_from :all

  use Rack::Turnout
  use Rack::JSONP

  helpers AuthenticationHelpers

  # Simple CORS support
  before do
    header 'Access-Control-Allow-Origin', '*'

    authenticate!
  end

  rescue_from Mongoid::Errors::DocumentNotFound do |e|
    Rack::Response.new({
        status: 404,
        message: 'Not found'
      }.to_json, 404)
  end

  mount API::V1

  route(:any, '*path') { error!('404 Not Found', 404) }
  route(:any, '/') { error!('404 Not Found', 404) }
end
