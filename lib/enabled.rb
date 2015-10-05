module Enabled
  def self.write?
    !Settings.dry_run
  end
  singleton_class.send(:alias_method, :email?, :write?)

  def self.third_party?
    Settings.third_party_apis
  end

  def self.write_to_third_party?
    write? && third_party?
  end
end
