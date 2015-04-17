module ServiceObjects
  class AssignEmailAddress < Base
    EMAIL_TYPE = :university
    MAKE_EMAIL_PRIMARY = true

    def call
      email_options = EmailAddressOptions.new(change.affiliations, change.preferred_name, change.first_name, change.middle_name, change.last_name).to_a
      return nil if email_options.none?

      unique_email = UniqueEmailAddress.new(email_options).best
      full_unique_email = GoogleAccount.full_email(unique_email)

      response = Trogdir::APIClient::Emails.new.create(uuid: change.person_uuid, address: full_unique_email, type: EMAIL_TYPE, primary: MAKE_EMAIL_PRIMARY).perform
      if response.success?
        :create
      else
        raise TrogdirAPIError, response.parse['error']
      end
    end

    def ignore?
      !(change.affiliation_added? && !change.university_email_exists?)
    end
  end
end
