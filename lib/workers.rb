# Namespace module for Sidekiq worker classes
module Workers
  # Exception for when an error occurs with Trogdir
  class TrogdirAPIError < StandardError; end

  require './lib/workers/deprovisioning'
  require './lib/workers/legacy_email_table'
  require './lib/workers/trogdir'

  require './lib/workers/check_inactive'
  require './lib/workers/check_never_active'
  require './lib/workers/create_alias_email'
  require './lib/workers/create_person_email'
  require './lib/workers/deprovision_google_account'
  require './lib/workers/handle_change'
  require './lib/workers/handle_changes'
  require './lib/workers/update_person_email'
  require './lib/workers/schedule_actions'
end
