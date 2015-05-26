module ServiceObjects
  class UpdateEmailAddress < Base
    def call
      UpdateLegacyEmailTable.new(change).call(change.new_university_email)
      :update
    end

    def ignore?
      !change.university_email_updated?
    end
  end
end
