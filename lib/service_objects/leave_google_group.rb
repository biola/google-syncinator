module ServiceObjects
  class LeaveGoogleGroup < Base
    def call
      changes = Whitelist.filter(change.left_groups).each do |group|
        @changed = true if google_account.leave! group
      end

      changes.any? && @changed ? :update : :skip
    end

    def ignore?
      Whitelist.filter(change.left_groups).none?
    end
  end
end
