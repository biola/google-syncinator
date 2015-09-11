module Workers
  # Namespace module for the Trogdir worker classes
  module Trogdir
    require './lib/workers/trogdir/change_error.rb'
    require './lib/workers/trogdir/change_finish.rb'
    require './lib/workers/trogdir/create_email.rb'
    require './lib/workers/trogdir/delete_email.rb'
  end
end
