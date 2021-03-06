# Mixin for deprovisioning accounts that are not active enough
module ActivityCheck
  # Finds and deprovisions accounts that have either never ben logged into, or have not been logged into in a long time.
  # @param type [Symbol] either :never_active or :inactive
  # @return [nil]
  def run_activity_check(type)
    unless [:never_active, :inactive].include? type
      raise ArgumentError, 'type must me :never_active or :inactive'
    end

    email_addresses = GoogleAccount.public_send(type)
    reason = DeprovisionSchedule.const_get("#{type}_reason".upcase)

    email_addresses.each do |email_address|
      Log.info "Checking #{email_address} because it is considered #{type.to_s.humanize(capitalize: false)}"

      if email = AccountEmail.current(email_address)
        if email.being_deprovisioned?
          Log.info "#{email_address} is already being deprovisioned. Skipping."
        elsif email.protected?
          Log.info "#{email_address} is protected. Skipping."
        elsif email.excluded?
          Log.info "#{email_address} is excluded. Skipping."
        else
          can_deprovision = if email.is_a? DepartmentEmail
            true
          elsif email.is_a? PersonEmail
            person = TrogdirPerson.new(email.uuid)
            EmailAddressOptions.not_required?(person.affiliations)
          end

          if can_deprovision
            Log.info "Scheduling deprovision of #{email_address}"
            schedule = Workers::Deprovisioning.schedule_for(email, type, true)

            Workers::ScheduleActions.perform_async email.id.to_s, schedule, reason
          else
            Log.info "#{email_address} is a required email. Skipping."
          end
        end
      else
        Log.warn "Could not find an AccountEmail with address #{email_address}. Skipping."
      end
    end

    # Emails that are pending deprovisioning because they were never active
    pending_emails = AccountEmail.where(:deprovision_schedules.elem_match => {reason: reason, completed_at: nil, canceled: nil})

    pending_emails.each do |email|
      # Cancel deprovisioning if they have become active
      email.cancel_deprovisioning! if email_addresses.exclude? email.address
    end

    nil
  end
end
