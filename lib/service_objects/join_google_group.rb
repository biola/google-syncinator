module ServiceObjects
  class JoinGoogleGroup < Base
    def call
      changes = Whitelist.filter(change.joined_groups).each do |group|
        changed = true if google_account.join! group
      end

      changes.any? && changed ? :update : :skip
    end

    def ignore?
      Whitelist.filter(change.joined_groups).none?
    end
  end
end
