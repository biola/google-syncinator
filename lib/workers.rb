module Workers
  require './lib/workers/assign_email_address'
  require './lib/workers/create_google_apps_account'
  require './lib/workers/trogdir_change_error_worker'
  require './lib/workers/trogdir_change_finish_worker'
  require './lib/workers/trogdir_change_listener'
  require './lib/workers/update_google_apps_account'
end
