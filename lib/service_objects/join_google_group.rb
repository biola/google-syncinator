module ServiceObjects
  class JoinAlphabetGroup < Base
    def call
      changes = Whitelist.filter(change.joined_groups).each do |group|
        alphabet_account.join! group
      end

      changes.any? ? :update : :skip
    end

    def ignore?
      Whitelist.filter(change.joined_groups).none?
    end
  end
end
