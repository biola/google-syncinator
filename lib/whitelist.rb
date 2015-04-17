module Whitelist
  def self.filter(groups)
    groups.map(&:to_s) & Settings.groups.whitelist
  end
end
