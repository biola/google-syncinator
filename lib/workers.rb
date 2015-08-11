# Namespace module for Sidekiq worker classes
module Workers
  # Exception for when an error occurs with Trogdir
  class TrogdirAPIError < StandardError; end

  require './lib/workers/deprovisioning'

  require './lib/workers/change_error'
  require './lib/workers/change_finish'
  require './lib/workers/check_inactive'
  require './lib/workers/check_never_active'
  require './lib/workers/create_trogdir_email'
  require './lib/workers/delete_trogdir_email'
  require './lib/workers/deprovision_google_account'
  require './lib/workers/expire_legacy_email_table'
  require './lib/workers/handle_change'
  require './lib/workers/handle_changes'
  require './lib/workers/insert_into_legacy_email_table'
  require './lib/workers/schedule_actions'
  require './lib/workers/unexpire_legacy_email_table'
  require './lib/workers/update_legacy_email_table'
end
