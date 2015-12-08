module Workers
  # Namespace module for the deprovisioning worker classes
  module Deprovisioning
    require './lib/workers/deprovisioning/base'
    require './lib/workers/deprovisioning/activate'
    require './lib/workers/deprovisioning/delete'
    require './lib/workers/deprovisioning/notify_of_closure'
    require './lib/workers/deprovisioning/notify_of_inactivity'
    require './lib/workers/deprovisioning/suspend'

    # Find the right deprovision schedule
    # @note Assumes the account_email should be deprovisioned
    # @param account_email [AccountEmail] AccountEmail to be deprovisioned
    # @param ever_active [:active, :inactive, :never_active] Has the account ever been active?
    # @param allowed [Boolean, nil] Whether the account is allowed to exist
    # @return [Array<Symbol, Integer>]
    def self.schedule_for(account_email, activity, allowed = nil)
      settings = Settings.deprovisioning.schedules
      allowance = allowed ? :allowed : :unallowed

      if account_email.is_a? DepartmentEmail
        settings.department_emails.send(activity)
      elsif account_email.is_a? PersonEmail
        raise ArgumentError, 'allowed is required for PersonEmails' if allowed.nil?

        settings.person_emails.send(allowance).send(activity)
      end
    end
  end
end
