class GoogleAccount
  class GoogleAppsAPIError < RuntimeError; end

  ZERO_DATE = '1970-01-01T00:00:00.000Z'

  attr_reader :email

  def initialize(email)
    @email = email
  end

  def exists?
    return false if data.nil?

    data.emails.map{|e| e['address']}.include? full_email
  end

  def available?
    !exists?
  end

  def suspended?
    data['suspended'].present?
  end

  def last_login
    return nil if data.nil?

    data['lastLoginTime'].to_i == 0 ? nil : data['lastLoginTime']
  end

  def logged_in?
    last_login.nil?
  end

  def never_logged_in?
    last_login.present?
  end

  def create_or_update!(first_name, last_name, department, title, privacy)
    if exists?
      update! first_name, last_name, department, title, privacy
      :update
    else
      create! first_name, last_name, department, title, privacy
      :create
    end
  end

  def create!(first_name, last_name, department, title, privacy)
    params = {
      primaryEmail: full_email,
      password: GoogleAccount.random_password,
      name: {
        familyName: last_name,
        givenName: first_name
      },
      organizations: [
        department: department,
        title: title
      ],
      includeInGlobalAddressList: !privacy
    }

    new_user = directory.users.insert.request_schema.new(params)

    result = api.execute api_method: directory.users.insert, body_object: new_user
    raise GoogleAppsAPIError, result.data['error']['message'] unless result.success?

    true
  end

  def update!(first_name, last_name, department, title, privacy)
    params = {
      name: {
        givenName: first_name,
        familyName: last_name
      },
      organizations: [
        department: department,
        title: title
      ],
      includeInGlobalAddressList: !privacy
    }

    user_updates = directory.users.update.request_schema.new(params)

    result = api.execute api_method: directory.users.update, parameters: {userKey: full_email}, body_object: user_updates
    raise GoogleAppsAPIError, result.data['error']['message'] unless result.success?

    true
  end

  def suspend!
    update_suspension! true
  end

  def unsuspend!
    update_suspension! false
  end

  def delete!
    result = api.execute api_method: directory.users.delete, parameters: {userKey: email}
    raise GoogleAppsAPIError, result.data['error']['message'] unless result.success?

    true
  end

  def join!(group, role = 'MEMBER')
    group = GoogleAccount.group_to_email(group)
    params = {email: full_email, role: role}

    new_member = directory.members.insert.request_schema.new(params)

    result = api.execute api_method: directory.members.insert, parameters: {groupKey: group}, body_object: new_member
    raise GoogleAppsAPIError, result.data['error']['message'] unless result.success?
  end

  def leave!(group)
    group = GoogleAccount.group_to_email(group)
    result = api.execute api_method: directory.members.delete, parameters: {groupKey: group, memberKey: full_email}
    raise GoogleAppsAPIError, result.data['error']['message'] unless result.success?
  end

  def full_email
    GoogleAccount.full_email(email)
  end

  def self.never_active
    page_token = nil
    never_active_emails = []

    loop do
      result = api.execute(
        api_method: reports.user_usage_report.get,
        parameters: {
          userKey: 'all',
          date: 3.days.ago.to_date.to_s, # TODO: grab from settings
          filters: "accounts:last_login_time==#{ZERO_DATE},accounts:is_disabled==false",
          parameters: 'accounts:last_login_time',
          fields: 'nextPageToken,usageReports(entity/userEmail,parameters)',
          pageToken: page_token
        }
      )

      raise GoogleAppsAPIError, result.error_message unless result.success?

      result.data.usage_reports.each do |report|
        never_active_emails << report.entity.user_email
      end

      break unless page_token = result.next_page_token
    end

    never_active_emails
  end

  def self.inactive
    page_token = nil
    inactive_emails = []

    loop do
      result = api.execute(
        api_method: reports.user_usage_report.get,
        parameters: {
          userKey: 'all',
          date: 3.days.ago.to_date.to_s, # TODO: grab from settings
          filters: "accounts:last_login_time<#{1.year.ago.iso8601},accounts:last_login_time>#{ZERO_DATE},accounts:is_disabled==false",
          parameters: 'accounts:last_login_time',
          fields: 'nextPageToken,usageReports(entity/userEmail,parameters)',
          pageToken: page_token
        }
      )

      raise GoogleAppsAPIError, result.error_message unless result.success?

      result.data.usage_reports.each do |report|
        # TODO: get time from Settings
        last_login = report.parameters.find{|p| p.name = 'accounts:last_login_time'}.datetime_value
        # It shouldn't be necessary to recheck the last_login here but better safe than sorry
        if last_login < 1.year.ago
          inactive_emails << report.entity.user_email
        end
      end

      break unless page_token = result.next_page_token
    end

    inactive_emails
  end

  def self.full_email(email)
    if email.include? '@'
      email
    else
      "#{email}@#{Settings.google.domain}"
    end
  end

  def self.group_to_email(group_name)
    full_email(group_name.to_s.downcase.gsub(/[^a-z0-9]+/, '.'))
  end

  def self.random_password
    rand(36**rand(16..42)).to_s(36)
  end

  private

  def update_suspension!(suspend = true)
    user_updates = directory.users.update.request_schema.new(suspend: suspend)

    result = api.execute api_method: directory.users.update, parameters: {userKey: full_email}, body_object: user_updates
    raise GoogleAppsAPIError, result.data['error']['message'] unless result.success?

    true
  end

  def self.api
    api = Google::APIClient.new(
      application_name: Settings.google.api_client.application_name,
      application_version: Settings.google.api_client.application_version)

    key = Google::APIClient::KeyUtils.load_from_pkcs12(Settings.google.api_client.key_path, Settings.google.api_client.secret)

    api.authorization = Signet::OAuth2::Client.new(
      token_credential_uri: 'https://accounts.google.com/o/oauth2/token',
      audience: 'https://accounts.google.com/o/oauth2/token',
      scope: Settings.google.api_client.scopes,
      issuer: Settings.google.api_client.issuer,
      signing_key: key)
    api.authorization.person = Settings.google.api_client.person
    api.authorization.fetch_access_token!
    api
  end

  def api
    return @api unless @api.nil?

    @api = self.class.api
  end

  def self.reports
    api.discovered_api('admin', 'reports_v1')
  end

  def self.directory
    api.discovered_api('admin', 'directory_v1')
  end

  def directory
    @directory ||= self.class.directory
  end

  def data
    @data ||= (
      result = api.execute(
        api_method: directory.users.get,
        # This will find by primary email or aliases according to Google's documentation
        parameters: {userKey: full_email}
      )

      result.success? ? result.data : nil
    )
  end
end
