module ServiceObjects
  class SyncAlphabetAccount < Base
    def call
      person = TrogdirPerson.new(change.person_uuid)
      alphabet_account.create_or_update!(person.first_or_preferred_name, person.last_name, person.department, person.title, person.privacy)
    end

    def ignore?
      !(change.university_email_added? || (change.account_info_updated? && change.university_email_exists?))
    end
  end
end
