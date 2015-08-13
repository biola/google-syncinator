# One-time import scripts for importing legacy data sources
namespace :import do
  # Import records from the MySQL WS email table
  desc 'Import from the legacy WS email table'
  task :legacy_email_table do
    REASON = 'Imported from WS email table'

    log_file = File.expand_path("../../../log/import_legacy_email_table-#{DateTime.now.strftime('%Y_%m_%d_%H_%M')}.log", __FILE__)
    log = Logger.new(log_file).tap do |logger|
      logger.formatter = Logger::Formatter.new
    end

    count = 0

    DB[:email].each do |rec|
      biola_id = rec[:idnumber]
      address = rec[:email]
      primary = !!rec[:primary]
      expiration_date = rec[:expiration_date]
      reusable_date = rec[:reusable_date]
      response = Trogdir::APIClient::People.new.by_id(id: biola_id, type: :biola_id).perform

      if response.status == 404
        log.warn %{Could not find Biola ID "#{biola_id}" in Trogdir}
      elsif response.success?
        uuid = response.parse['uuid']

        if UniversityEmail.where(uuid: uuid, address: address).any?
          log.info %{University Email for UUID: "#{uuid}", address: "#{address}" already exists}
        else
          email = UniversityEmail.create! uuid: uuid, address: address, primary: primary

          if expiration_date
            email.deprovision_schedules.create action: :suspend, reason: REASON, scheduled_for: expiration_date, completed_at: expiration_date
          end

          if reusable_date
            email.deprovision_schedules.create action: :delete, reason: REASON, scheduled_for: reusable_date, completed_at: reusable_date
          end

          log.info %{Imported University Email for UUID: "#{uuid}", Biola ID: "#{biola_id}", Email: "#{address}"}
          count += 1
        end
      else
        fail response.parse['error']
      end
    end

    puts "Imported #{count} records"
  end
end
