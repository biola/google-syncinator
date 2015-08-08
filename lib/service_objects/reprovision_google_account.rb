module ServiceObjects
  class ReprovisionGoogleAccount < Base
    class ReprovisionError < StandardError; end

    def call
      # Activation can always happen right away, so no need to schedule it for the future like the others
      # We'll delay it just a few seconds to prevent race conditions
      reprovisionable_email.deprovision_schedules << DeprovisionSchedule.new(action: :activate, scheduled_for: DateTime.now) if !Settings.dry_run?
      Workers::ScheduleActions.perform_async(reprovisionable_email.uuid, 10, :activate)
      :create
    end

    def ignore?
      return true if UniversityEmail.active? change.person_uuid
      return true unless change.affiliations_changed?
      return true if UniversityEmail.where(uuid: change.person_uuid, address: change.university_email).first.try(:excluded?)
      !(EmailAddressOptions.required?(change.affiliations) && reprovisionable_email.present?)
    end

    private

    def reprovisionable_email
      @reprovisionable_email ||= UniversityEmail.find_reprovisionable(change.person_uuid)
    end
  end
end
