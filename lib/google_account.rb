class GoogleAccount
  attr_reader :email

  class GoogleAppsAPIError < RuntimeError; end

  def initialize(email)
    @email = email
  end

  def exists?
    result = api.execute(
      api_method: directory.users.get,
      # This will find by primary email or aliases according to Google's documentation
      parameters: {userKey: full_email}
    )

    return false unless result.success?

    result.data.emails.map{|e| e['address']}.include? full_email
  end

  def available?
    !exists?
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

  def self.full_email(email)
    if email.include? '@'
      email
    else
      "#{email}@#{Settings.google.domain}"
    end
  end

  def self.group_to_email(group_name)
    full_email(group_name.to_s.downcase.gsub /[^a-z0-9]+/, '.')
  end

  def self.random_password
    rand(36**rand(16..42)).to_s(36)
  end

  private

  def api
    return @api unless @api.nil?

    @api = Google::APIClient.new(
      application_name: Settings.google.api_client.application_name,
      application_version: Settings.google.api_client.application_version)

    key = Google::APIClient::KeyUtils.load_from_pkcs12(Settings.google.api_client.key_path, Settings.google.api_client.secret)

    @api.authorization = Signet::OAuth2::Client.new(
      token_credential_uri: 'https://accounts.google.com/o/oauth2/token',
      audience: 'https://accounts.google.com/o/oauth2/token',
      scope: Settings.google.api_client.scopes,
      issuer: Settings.google.api_client.issuer,
      signing_key: key)
    @api.authorization.person = Settings.google.api_client.person
    @api.authorization.fetch_access_token!
    @api
  end

  def directory
    @directory ||= api.discovered_api('admin', 'directory_v1')
  end
end
