module Emails
  class NotifyOfClosure < Base
    def body
<<EOD
Dear #{trogdir_person.first_or_preferred_name},

This is to inform you that this email account will automatically be disabled in #{disable_days_from_now} days with no further notice. Please back up any data you would like to keep.

If you are still affiliated with Biola University or believe this to be a mistake, please contact the IT Helpdesk immediately at it.helpdesk@biola.edu or by phone at (562) 903 4740. Direct responses to this email will not be read.

Sincerely,
Application Services
Biola University
EOD
    end
  end
end
