module Deprovisioning
  require './lib/workers/deprovisioning/activate'
  require './lib/workers/deprovisioning/delete'
  require './lib/workers/deprovisioning/notify_of_closure'
  require './lib/workers/deprovisioning/notify_of_inactivity'
  require './lib/workers/deprovisioning/suspend'
end
