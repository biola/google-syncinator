module ServiceObjects
  # Create or update a Google account along with its details
  class SyncGoogleAccount < Base
    # Create or update the account and it's details including unsuspending it
    #   if it's currently suspended
    # @return [:create, :update] the action
    def call
      person = TrogdirPerson.new(change.person_uuid)
      # NOTE: temporarily disabling org unit changes
      # org_unit_path = OrganizationalUnit.path_for(person)

      google_account.unsuspend! if google_account.suspended?
      google_account.update!(
        first_name: person.first_or_preferred_name,
        last_name: person.last_name,
        department: person.department,
        title: person.title,
        privacy: person.privacy#,
        # NOTE: temporarily disabling org unit changes
        # org_unit_path: org_unit_path
      )

      :update
    end

    # Should this change trigger a Google account sync
    # @return [Boolean]
    def ignore?
      org_unit_changed = org_unit(change.old_affiliations) != org_unit(change.new_affiliations)
      !(change.university_email_exists? && (change.account_info_updated? || org_unit_changed))
    end

    private

    def org_unit(affiliations)
      OrganizationalUnit.path_for(affiliations)
    end
  end
end
