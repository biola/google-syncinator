module ServiceObjects
  # Handles joining the appropriate groups in google when a group change occurs
  class JoinGoogleGroup < Base
    # Join the Google Group if they are in the whitelisted groups
    # @return [:update, :skip] action taken
    def call
      changes = Whitelist.filter(change.joined_groups).each do |group|
        google_account.join! group
      end

      changes.any? ? :update : :skip
    end

    # Should this change trigger a group joining
    # @return [Boolean]
    def ignore?
      Whitelist.filter(change.joined_groups).none?
    end
  end
end
