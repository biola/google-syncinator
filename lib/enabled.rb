module Enabled
  def self.write?
    !Settings.dry_run?
  end
  singleton_class.send(:alias_method, :email?, :write?)

  def self.third_party?
    write? && Settings.third_party_apis?
  end
end
