# Helper module to wrap certain settings for testing and staging
module Enabled
  # Should writes to databases and APIs be performed
  def self.write?
    !Settings.dry_run
  end
  singleton_class.send(:alias_method, :email?, :write?)

  # Should calls to third-party APIs like Google be performed
  def self.third_party?
    Settings.third_party_apis
  end

  # Should writes to third-party APIs like Google be performed
  def self.write_to_third_party?
    write? && third_party?
  end
end
