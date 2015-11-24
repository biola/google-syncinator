# One-time import scripts for importing legacy data sources
namespace :import do
  # Import records from the MySQL WS email table
  # @note This task should be run before the department_emails task
  desc 'Import from the legacy WS email table'
  task :legacy_email_table do
    REASON = 'Imported from WS email table'

    log_file = File.expand_path("../../../log/import_legacy_email_table-#{DateTime.now.strftime('%Y_%m_%d_%H_%M')}.log", __FILE__)
    log = Logger.new(log_file).tap do |logger|
      logger.formatter = Logger::Formatter.new
    end

    count = 0

    all_emails = DB[:email].to_a
    person_emails = all_emails.select { |rec| !!rec[:primary] }
    alias_emails = all_emails.select { |rec| !rec[:primary] }

    person_emails.each do |rec|
      biola_id = rec[:idnumber]
      address = rec[:email]
      expiration_date = rec[:expiration_date]
      reusable_date = rec[:reusable_date]
      response = Trogdir::APIClient::People.new.by_id(id: biola_id, type: :biola_id).perform

      if response.status == 404
        log.warn %{Could not find Biola ID "#{biola_id}" in Trogdir}
      elsif response.success?
        uuid = response.parse['uuid']

        if AccountEmail.where(uuid: uuid, address: address).any?
          log.info %{Account Email for UUID: "#{uuid}", address: "#{address}" already exists}
        else
          email = PersonEmail.create! uuid: uuid, address: address

          if expiration_date
            email.deprovision_schedules.create action: :suspend, reason: REASON, scheduled_for: expiration_date, completed_at: expiration_date
          end

          if reusable_date
            email.deprovision_schedules.create action: :delete, reason: REASON, scheduled_for: reusable_date, completed_at: reusable_date
          end

          log.info %{Imported Account Email for UUID: "#{uuid}", Biola ID: "#{biola_id}", Email: "#{address}"}
          count += 1
        end
      else
        fail response.parse['error']
      end
    end

    alias_emails.each do |rec|
      biola_id = rec[:idnumber]
      address = rec[:email]
      response = Trogdir::APIClient::People.new.by_id(id: biola_id, type: :biola_id).perform

      if response.status == 404
        log.warn %{Could not find Biola ID "#{biola_id}" in Trogdir}
      elsif response.success?
        uuid = response.parse['uuid']

        if AliasEmail.where(address: address, :status.ne => :deleted).any?
          log.info %{Alias Email with address: "#{address}" already exists}
        else
          person_email = PersonEmail.find_by(uuid: uuid, state: :active)
          AliasEmail.create! account_email: person_email, address: address

          log.info %{Imported Alias Email for UUID: "#{uuid}", Biola ID: "#{biola_id}", Email: "#{address}"}
          count += 1
        end
      else
        fail response.parse['error']
      end
    end

    puts "Imported #{count} records"
  end

  # Import department email records from Google Apps accounts
  # @note This is meant to be run after the legacy_email_table task as it will consider anything in Google but not in the university_emails collection as a department account.
  desc 'DepartmentEmails from Google Apps'
  task :department_emails do
    REASON = 'Imported from Google Apps'

    log_file = File.expand_path("../../../log/import_department_emails-#{DateTime.now.strftime('%Y_%m_%d_%H_%M')}.log", __FILE__)
    log = Logger.new(log_file).tap do |logger|
      logger.formatter = Logger::Formatter.new
    end

    log.info "Importing department emails from Google Apps..."

    account_addresses = AccountEmail.where(state: :active).pluck(:address)
    all_accounts = GoogleAccount.all
    department_accounts = all_accounts.reject { |acct| account_addresses.include? acct.primary_email }

    log.info "Found #{department_accounts.length} department accounts in Google Apps"

    department_accounts.each do |account|
      log.info "Importing #{account.primary_email}"

      email = DepartmentEmail.new(address: account.primary_email, created_at: account.creation_time)
      # NOTE: Bypass validaton to get around the fact that we have no uuids to import
      email.save! validate: false

      log.info "#{email.address} imported to DepartmentEmail id=#{email.id}"

      account.aliases.each do |alias_address|
        alias_email = AliasEmail.create! address: alias_address, account_email: email
        log.info "Created alias #{alias_address} id=#{alias_email.id} for #{email.id}"
      end

      if account.suspended
        sched = email.deprovision_schedules.build action: :suspend, reason: REASON, scheduled_for: Time.now, completed_at: Time.now
        sched.account_email.save! validate: false
        log.info "Created suspension record for #{email.address} id=#{email.id}"
      end

      log.info "Finished importing #{account.primary_email}"
    end

    log.info "Finished importing #{department_accounts.length} department accounts"
  end
end
