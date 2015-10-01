# Version 1 of the Grape API
class API::V1 < Grape::API
  require './lib/api/versions/v1/entities/deprovision_schedule_entity'
  require './lib/api/versions/v1/entities/exclusion_entity'
  require './lib/api/versions/v1/entities/account_email_entity'
  require './lib/api/versions/v1/entities/alias_email_entity'
  require './lib/api/versions/v1/entities/person_email_entity'
  require './lib/api/versions/v1/entities/university_email_entity'
  require './lib/api/versions/v1/person_emails_api'
  require './lib/api/versions/v1/alias_emails_api'
  require './lib/api/versions/v1/deprovision_schedules_api'
  require './lib/api/versions/v1/emails_api'
  require './lib/api/versions/v1/exclusions_api'

  version 'v1', using: :path, vendor: :google_syncinator

  mount EmailsAPI
  mount PersonEmailsAPI
  mount AliasEmailsAPI

  resource 'emails/:email_id' do
    mount DeprovisionSchedulesAPI
    mount ExclusionsAPI
  end
end
