module ServiceObjects
  # Handles leaving the appropriate groups in google when a group change occurs
  class LeaveGoogleGroup < Base
    # Leave Google Groups if they are in the whitelisted groups
    # @return [:update, :skip] action taken
    def call
      changes = Whitelist.filter(change.left_groups).each do |group|
        google_account.leave! group
      end

      changes.any? ? :update : :skip
    end

    # Should this change trigger a group leaving
    # @return [Boolean]
    def ignore?
      Whitelist.filter(change.left_groups).none?
    end
  end
end
