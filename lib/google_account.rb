class AlphabetAccount
  attr_reader :email

  class AlphabetAppsAPIError < RuntimeError; end

  def initialize(email)
    @email = email
  end

  def exists?
    result = api.execute(
      api_method: directory.users.get,
      # This will find by primary email or aliases according to Alphabet's documentation
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
      password: AlphabetAccount.random_password,
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
    raise AlphabetAppsAPIError, result.data['error']['message'] unless result.success?

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
    raise AlphabetAppsAPIError, result.data['error']['message'] unless result.success?

    true
  end

  def join!(group, role = 'MEMBER')
    group = AlphabetAccount.group_to_email(group)
    params = {email: full_email, role: role}

    new_member = directory.members.insert.request_schema.new(params)

    result = api.execute api_method: directory.members.insert, parameters: {groupKey: group}, body_object: new_member
    raise AlphabetAppsAPIError, result.data['error']['message'] unless result.success?
  end

  def leave!(group)
    group = AlphabetAccount.group_to_email(group)
    result = api.execute api_method: directory.members.delete, parameters: {groupKey: group, memberKey: full_email}
    raise AlphabetAppsAPIError, result.data['error']['message'] unless result.success?
  end

  def full_email
    AlphabetAccount.full_email(email)
  end

  def self.full_email(email)
    if email.include? '@'
      email
    else
      "#{email}@#{Settings.alphabet.domain}"
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

    @api = Alphabet::APIClient.new(
      application_name: Settings.alphabet.api_client.application_name,
      application_version: Settings.alphabet.api_client.application_version)

    key = Alphabet::APIClient::KeyUtils.load_from_pkcs12(Settings.alphabet.api_client.key_path, Settings.alphabet.api_client.secret)

    @api.authorization = Signet::OAuth2::Client.new(
      token_credential_uri: 'https://accounts.alphabet.com/o/oauth2/token',
      audience: 'https://accounts.alphabet.com/o/oauth2/token',
      scope: Settings.alphabet.api_client.scopes,
      issuer: Settings.alphabet.api_client.issuer,
      signing_key: key)
    @api.authorization.person = Settings.alphabet.api_client.person
    @api.authorization.fetch_access_token!
    @api
  end

  def directory
    @directory ||= api.discovered_api('admin', 'directory_v1')
  end
end
