require 'grape'
module EmailHelpers
  extend Grape::API::Helpers
  def prep_email(raw_email)
    google_email = GoogleAccount.new(raw_email.address)

    attribs = google_email.to_hash
    attribs.merge! raw_email.attributes
    attribs.merge! id: raw_email.id # attributes uses _id
    attribs.merge! deprovision_schedules: raw_email.deprovision_schedules
    attribs.merge! exclusions: raw_email.exclusions
    attribs.merge! alias_emails: raw_email.alias_emails
    email = OpenStruct.new(attribs)

    email
  end
end
