module ServiceObjects
  class LeaveGoogleGroup < Base
    def call
      changes = Whitelist.filter(change.left_groups).each do |group|
        google_account.leave! group
      end

      changes.any? ? :update : :skip
    end

    def ignore?
      Whitelist.filter(change.left_groups).none?
    end
  end
end
