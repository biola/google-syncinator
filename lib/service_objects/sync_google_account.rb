module ServiceObjects
  class SyncGoogleAccount < Base
    def call
      google_account.create_or_update!(change.first_name, change.last_name, change.department, change.title, change.privacy)
    end

    def ignore?
      !(change.university_email_added? || (change.account_info_updated? && change.university_email_exists?))
    end
  end
end
