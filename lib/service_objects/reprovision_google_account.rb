module ServiceObjects
  class ReprovisionGoogleAccount < Base
    class ReprovisionError < StandardError; end

    def call
      Workers::Deprovisioning::Activate.perform_async(reprovisionable_email.id)
      :create
    end

    def ignore?
      return true if UniversityEmail.active? change.person_uuid
      return true unless change.affiliations_changed?
      return true if UniversityEmail.where(uuid: change.person_uuid, address: change.university_email).first.try(:excluded?)
      !(EmailAddressOptions.allowed?(change.affiliations) && reprovisionable_email.present?)
    end

    private

    def reprovisionable_email
      @reprovisionable_email ||= UniversityEmail.find_reprovisionable(change.person_uuid)
    end
  end
end
