module Emails
  class Base
    def initialize(deprovision_schedule)
      @deprovision_schedule = deprovision_schedule
    end

    def subject
      if disable_days_from_now < 7
        "#{university_email.address} Email Account Closure"
      else
        "#{university_email.address} Email Account Closure in #{disable_days_from_now} DAYS"
      end
    end

    def body
      raise NotImplementedError, 'Must override #body in child class'
    end

    def send!
      if !Settings.dry_run?
        send_to = university_email.address
        email_body = body

        Mail.deliver do
          from     Settings.email.from
          to       send_to
          subject  subject
          body     email_body
        end
      end

      Log.info %{Sent "#{subject}" email}
    end

    private

    attr_reader :deprovision_schedule

    def disable_days_from_now
      university_email.disable_date.to_date.mjd - Date.today.mjd
    end

    def university_email
      deprovision_schedule.university_email
    end

    # This is here because it is commonly used in subclasses
    def trogdir_person
      @trogdir_person ||= TrogdirPerson.new(university_email.uuid)
    end

  end
end
