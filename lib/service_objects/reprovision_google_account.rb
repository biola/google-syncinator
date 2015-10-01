module ServiceObjects
  # Re-activate an email account that once belonged to the user
  class ReprovisionGoogleAccount < Base
    # Reactivate a suspended or deleted account that used to belong to the user
    # @return [:create]
    def call
      # We'll delay the worker just a few seconds to prevent race conditions
      Workers::ScheduleActions.perform_async(reprovisionable_email.id.to_s, [10, :activate], DeprovisionSchedule::GAINED_AFFILIATION_REASON)

      :create
    end

    # Should this change trigger a reprovisioning
    # @return [Boolean]
    def ignore?
      return true unless change.affiliations_changed?
      return true if PersonEmail.active? change.person_uuid
      return true if PersonEmail.where(uuid: change.person_uuid, address: change.university_email).first.try(:excluded?)
      !(EmailAddressOptions.required?(change.affiliations) && reprovisionable_email.present?)
    end

    private

    # Simple wrapper for PersonEmail#find_reprovisionable
    # @return [PersonEmail] an PersonEmail that used to belong to the user but is no longer active
    # @see PersonEmail#find_reprovisionable
    def reprovisionable_email
      @reprovisionable_email ||= PersonEmail.find_reprovisionable(change.person_uuid)
    end
  end
end
