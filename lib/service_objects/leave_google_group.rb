module ServiceObjects
  class LeaveAlphabetGroup < Base
    def call
      changes = Whitelist.filter(change.left_groups).each do |group|
        alphabet_account.leave! group
      end

      changes.any? ? :update : :skip
    end

    def ignore?
      Whitelist.filter(change.left_groups).none?
    end
  end
end
