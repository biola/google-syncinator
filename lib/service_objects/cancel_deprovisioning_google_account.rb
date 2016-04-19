module ServiceObjects
  # Cancel the deprovisioning of an email account because affiliations have changed
  class CancelDeprovisioningGoogleAccount < Base
    # Cancel the deprovisioning of an email account because affiliations have changed
    # @return [:update]
    def call
      PersonEmail.where(uuid: change.person_uuid).each do |email|
        email.deprovision_schedules.each do |sched|
          if sched.pending? && sched.action != :activate
            sched.cancel!
          end
        end
      end

      :update
    end

    # Should this change trigger a deprovisioning cancelation
    # @return [Boolean]
    def ignore?
      return true unless change.affiliation_added?
      return true unless EmailAddressOptions.allowed?(change.affiliations)

      PersonEmail.where(uuid: change.person_uuid).each do |email|
        unless email.excluded?
          return false if cancellable_schedules(email).any?
        end
      end

      true
    end

    private

    def cancellable_schedules(email)
      email.deprovision_schedules.select do |sched|
        sched.pending? && sched.action != :activate
      end
    end
  end
end
