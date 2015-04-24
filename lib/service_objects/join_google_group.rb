module ServiceObjects
  class JoinGoogleGroup < Base
    def call
      changes = Whitelist.filter(change.joined_groups).each do |group|
        google_account.join! group
      end

      changes.any? ? :update : :skip
    end

    def ignore?
      Whitelist.filter(change.joined_groups).none?
    end
  end
end
