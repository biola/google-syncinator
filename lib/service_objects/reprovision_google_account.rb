module ServiceObjects
  class ReprovisionGoogleAccount < Base
    class ReprovisionError < StandardError; end

    def call
      reprovisionable_email.deprovision_schedules << DeprovisionSchedule.new(action: :activate, scheduled_for: DateTime.now, completed_at: DateTime.now)
      reprovisionable_email.update state: :active
      Workers::CreateTrogdirEmail.perform_async change.person_uuid, reprovisionable_email.address
      Workers::UnexpireLegacyEmailTable.perform_async(change.biola_id, reprovisionable_email.address)

      :create
    end

    def ignore?
      return true if UniversityEmail.active? change.person_uuid
      return true unless change.affiliations_changed?
      # TODO: check for exclusions
      !(EmailAddressOptions.allowed?(change.affiliations) && reprovisionable_email.present?)
    end

    private

    def reprovisionable_email
      @reprovisionable_email ||= UniversityEmail.find_reprovisionable(change.person_uuid)
    end
  end
end
