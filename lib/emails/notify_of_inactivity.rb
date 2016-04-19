module Emails
  # Sends an email notifying the email owner that their account is about to close due to inactivity
  class NotifyOfInactivity < Base
    # The body of the email
    # @return [String] the body of the email
    def body
<<EOD
Dear #{trogdir_people.map(&:first_or_preferred_name).to_sentence},

Your #{account_email.address} email account will be disabled in #{disable_days_from_now} days due to inactivity. To keep this Biola University email account, simply sign in before your account is disabled. If you no longer use your #{account_email.address} email account, no action is required. Your account will be disabled automatically.

To sign in and keep your account, point your browser to http://mail.biola.edu and log in using #{account_email.address} and your NetID password. If you do not know your NetID password, you can visit https://login.biola.edu/reset-password to choose a new one.

If you have any questions, please contact the IT Helpdesk at it.helpdesk@biola.edu or by phone at (562) 903 4740. Direct responses to this email will not be read.

Sincerely,
Application Services
Biola University
EOD
    end
  end
end
