module ActivityCheck
  def run_activity_check(type)
    unless [:never_active, :inactive].include? type
      raise ArgumentError, 'type must me :never_active or :inactive'
    end

    email_addresses = GoogleAccount.send(type)
    reason = DeprovisionSchedule.const_get("#{type}_reason".upcase)

    email_addresses.each do |email_address|
      Log.info "Checking #{email_address} because it is considered #{type.to_s.humanize(capitalize: false)}"

      if email = AccountEmail.current(email_address)
        if email.being_deprovisioned?
          Log.info "#{email_address} is already being deprovisioned. Skipping."
        elsif email.protected?
          Log.info "#{email_address} is protected. Skipping."
        else
          person = TrogdirPerson.new(email.uuid)

          if EmailAddressOptions.not_required?(person.affiliations)
            Log.info "Scheduling deprovision of #{email_address}"
            Workers::ScheduleActions.perform_async email.id.to_s, Settings.deprovisioning.schedules.allowed.send(type), reason
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
