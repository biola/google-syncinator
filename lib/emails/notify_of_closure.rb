module Emails
  # Sends an email notifying the email owner that their account is about to close
  class NotifyOfClosure < Base
    # The body of the email
    # @return [String] the body of the email
    def body
<<EOD
Dear #{trogdir_people.map(&:first_or_preferred_name).to_sentence},

This is to inform you that this email account will automatically be disabled in #{disable_days_from_now} days with no further notice. Please back up any data you would like to keep.

If you are still affiliated with Biola University or believe this to be a mistake, please contact the IT Helpdesk immediately at it.helpdesk@biola.edu or by phone at (562) 903 4740. Direct responses to this email will not be read.

Sincerely,
Application Services
Biola University
EOD
    end
  end
end
