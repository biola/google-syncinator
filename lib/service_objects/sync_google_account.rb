module ServiceObjects
  # Create or update a Google account along with its details
  class SyncGoogleAccount < Base
    # Create or update the account and it's details including unsuspending it
    #   if it's currently suspended
    # @return [:create, :update] the action
    def call
      person = TrogdirPerson.new(change.person_uuid)
      google_account.unsuspend! if google_account.suspended?
      google_account.update!(person.first_or_preferred_name, person.last_name, person.department, person.title, person.privacy)

      :update
    end

    # Should this change trigger a Google account sync
    # @return [Boolean]
    def ignore?
      !(change.account_info_updated? && change.university_email_exists?)
    end
  end
end
