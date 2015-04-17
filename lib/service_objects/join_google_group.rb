module ServiceObjects
  class JoinGoogleGroup < Base
    def call
      Whitelist.filter(change.joined_groups).each do |group|
        google_account.join! group
      end
    end

    def ignore?
      Whitelist.filter(change.joined_groups).none?
    end
  end
end
