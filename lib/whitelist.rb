# Whitelist of Trogdir groups that are also in Google and should be managed
module Whitelist
  # Filter a list of groups down to the ones that are whitelisted
  # @param groups [Array<String>] a list of groups to be reduced by the whielist
  # @return [Array<String>] the groups fro the groups param that are whitelisted
  def self.filter(groups)
    groups.map(&:to_s) & Settings.groups.whitelist
  end
end
