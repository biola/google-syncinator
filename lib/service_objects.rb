# Namespace module for service object classes
module ServiceObjects
  require './lib/service_objects/base'
  require './lib/service_objects/assign_email_address'
  require './lib/service_objects/cancel_deprovisioning_google_account'
  require './lib/service_objects/deprovision_google_account'
  require './lib/service_objects/handle_change'
  require './lib/service_objects/join_google_group'
  require './lib/service_objects/leave_google_group'
  require './lib/service_objects/reprovision_google_account'
  require './lib/service_objects/sync_google_account'
  require './lib/service_objects/update_biola_id'
end
