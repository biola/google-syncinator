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
        "#{account_email.address} Email Account Closure"
      else
        "#{account_email.address} Email Account Closure in #{disable_days_from_now} DAYS"
      end
    end

    # @abstract Subclass and override {#body} to implement
    # Body message of the email
    # @return [String] email body
    def body
      raise NotImplementedError, 'Must override #body in child class'
    end

    # Send the email to the AccountEmail#address associated with the
    # `deprovision_schedule`
    # @return [Object] Mail object
    # @return [false] if no email sent
    def send!
      mail_obj = false

      if !Settings.dry_run?
        send_to = account_email.address
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
      return nil if account_email.disable_date.nil?
      account_email.disable_date.to_date.mjd - Date.today.mjd
    end

    # The AccountEmail parent of the `deprovision_schedule`
    # @return [AccountEmail]
    def account_email
      deprovision_schedule.account_email
    end

    # The TrogdirPerson associated with the `account_email`
    # @note This is here because it is commonly used in subclasses
    # @return [TrogdirPerson] the trogdir person who the email belongs to
    def trogdir_person
      # TODO: this will have to be reworked to support department emails
      @trogdir_person ||= TrogdirPerson.new(account_email.uuid)
    end
  end
end
