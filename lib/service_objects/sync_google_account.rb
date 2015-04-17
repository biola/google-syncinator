module ServiceObjects
  class SyncGoogleAccount < Base
    def call
      GoogleAccount.new(change.university_email).create_or_update!(change.first_name, change.last_name, change.department, change.title, change.privacy)
    end

    def self.ignore?(change)
      !(change.university_email_added? || (change.account_info_updated? && change.university_email_exists?))
    end
  end
end
