module Emails
  # Base class for email objects. Handles all the dirty work of sending an email
  class Base
    # Initializes a new Email object
    # @param deprovision_schedule [DeprovisionSchedule]
    def initialize(deprovision_schedule)
      @deprovision_schedule = deprovision_schedule
    end

    # The subject line of the email
    # @return [String] email subject
    def subject
      if disable_days_from_now.to_i < 7
        "#{university_email.address} Email Account Closure"
      else
        "#{university_email.address} Email Account Closure in #{disable_days_from_now} DAYS"
      end
    end

    # @abstract Subclass and override {#body} to implement
    # Body message of the email
    # @return [String] email body
    def body
      raise NotImplementedError, 'Must override #body in child class'
    end

    # Send the email to the UniversityEmail#address associated with the
    # `deprovision_schedule`
    # @return [Object] Mail object
    # @return [false] if no email sent
    def send!
      mail_obj = false

      if !Settings.dry_run?
        send_to = university_email.address
        email_body = body

        mail_obj = Mail.deliver do
          from     Settings.email.from
          to       send_to
          subject  subject
          body     email_body
        end
      end

      Log.info %{Sent "#{subject}" email}

      mail_obj
    end

    private

    # @!attribute [r] deprovision_schedule
    #   @return [DeprovisionSchedule] the deprovision schedule for which an email will be sent
    attr_reader :deprovision_schedule

    # How many days it will be until the email is suspended or deleted
    # @return [Integer] days until the email is suspended or deleted
    # @return [nil] if email is not scheduled for suspension or deletion
    def disable_days_from_now
      return nil if university_email.disable_date.nil?
      university_email.disable_date.to_date.mjd - Date.today.mjd
    end

    # The UniversityEmail parent of the `deprovision_schedule`
    # @return [UniversityEmail]
    def university_email
      deprovision_schedule.university_email
    end

    # The TrogdirPerson associated with the `university_email`
    # @note This is here because it is commonly used in subclasses
    # @return [TrogdirPerson] the trogdir person who the email belongs to
    def trogdir_person
      @trogdir_person ||= TrogdirPerson.new(university_email.uuid)
    end
  end
end
