module Workers
  # Namespace module for the legacy email table worker classes
  module LegacyEmailTable
    require './lib/workers/legacy_email_table/expire'
    require './lib/workers/legacy_email_table/insert'
    require './lib/workers/legacy_email_table/unexpire'
    require './lib/workers/legacy_email_table/update_id'
  end
end
