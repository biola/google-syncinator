# Version 1 of the Grape API
class API::V1 < Grape::API
  require './lib/api/versions/v1/entities/deprovision_schedule_entity'
  require './lib/api/versions/v1/entities/exclusion_entity'
  require './lib/api/versions/v1/entities/university_email_entity'
  require './lib/api/versions/v1/emails.rb'

  version 'v1', using: :path, vendor: :google_syncinator

  mount Emails
end
