module ServiceObjects
  class LeaveGoogleGroup < Base
    def call
      Whitelist.filter(change.left_groups).each do |group|
        google_account.leave! group
      end
    end

    def ignore?
      Whitelist.filter(change.left_groups).none?
    end
  end
end
