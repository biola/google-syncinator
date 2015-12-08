# A wrapper object for the Google Admin API
# @note This class traps the google-api-client gem. See
#   https://github.com/google/google-api-ruby-client for details.
class GoogleAccount
  # Exception for when an error occurs with the Google API
  class GoogleAppsAPIError < RuntimeError; end

  # How a null date is represented in the Google APIs
  ZERO_DATE = '1970-01-01T00:00:00.000Z'

  # The primary address of the Google account
  # @return [String]
  attr_reader :email

  # Initialize a new GoogleAccount object by it's email address
  def initialize(email)
    @email = email
  end

  # The account's givenName in Google
  # @return [String]
  def first_name
    data['name']['givenName']
  end

  # The account's familyName in Google
  # @return [String]
  def last_name
    data['name']['familyName']
  end

  # The account's organization department in Google
  # @return [String]
  def department
    data['organizations'].try(:first).try :[], 'department'
  end

  # The account's organization title in Google
  # @return [String]
  def title
    data['organizations'].try(:first).try :[], 'title'
  end

  # The account's includeInGlobalAddressList value in Google
  # @return [Boolean]
  def privacy
    !data['includeInGlobalAddressList']
  end

  # The account's orgUnitPath in Google
  # @return [String]
  def org_unit_path
    data['orgUnitPath']
  end

  # The object's properties as a hash
  # @return [Hash<Symbol, Object>]
  def to_hash
    {
      address: full_email,
      first_name: first_name,
      last_name: last_name,
      department: department,
      title: title,
      privacy: privacy,
      org_unit_path: org_unit_path
    }
  end

  # Is the email account available?
  # @note opposite of exists?
  # @see #exists?
  def available?
    !exists?
  end

  # Is the account currently suspended?
  def suspended?
    !!data.try(:[], 'suspended').try(:present?)
  end

  # Has the user logged in within the configured amount of time?
  def active?
    last_login.to_i >= (Time.now - Settings.deprovisioning.inactive_after).to_i
  end

  # Has the user not logged in within the configured amount of time?
  def inactive?
    !active?
  end

  # Has the user ever logged in?
  # @note opposite of #never_logged_in?
  # @see #never_logged_in?
  def logged_in?
    last_login.present?
  end

  # Has the user never logged in?
  # @note opposite of #logged_in?
  # @see #logged_in?
  def never_logged_in?
    last_login.nil?
  end
  alias :never_active? :never_logged_in?

  # Creates Google Apps alias email address
  # @param address [String] the alias email address to create
  # @return [true]
  def create_alias!(address)
    new_alias = directory.users.aliases.insert.request_schema.new(alias: address)

    safe_execute api_method: directory.users.aliases.insert, parameters: {userKey: full_email}, body_object: new_alias

    true
  end

  # Create a new Google Apps account
  # @option params [String] :first_name The users first name
  # @option params [String] :last_name The users last name
  # @option params [String, nil] :department The users department
  # @option params [String, nil] :title The users title
  # @option params [Boolean] :privacy The users privacy setting
  # @option params [String] :org_unit_path ('/') The users organization unit path
  # @return [true]
  # @note first_name and last_name are required
  def create!(params)
    params[:address] = full_email
    # Defaults
    params[:org_unit_path] = '/' unless params.has_key? :org_unit_path
    params[:password] = GoogleAccount.random_password unless params.has_key? :password

    google_params = self.class.to_google_params(params)

    new_user = directory.users.insert.request_schema.new(google_params)

    safe_execute api_method: directory.users.insert, body_object: new_user

    true
  end

  # Updates a Google Apps account's details
  # @option params [String] :first_name The users first name
  # @option params [String] :last_name The users last name
  # @option params [String] :password The users password
  # @option params [String, nil] :department The users department
  # @option params [String, nil] :title The users title
  # @option params [Boolean] :privacy The users privacy setting
  # @option params [String] :org_unit_path The users organization unit path
  # @return [true]
  def update!(params)
    google_params = self.class.to_google_params(params)

    user_updates = directory.users.update.request_schema.new(google_params)

    safe_execute api_method: directory.users.update, parameters: {userKey: full_email}, body_object: user_updates

    true
  end

  # Renames a Google Apps account's primary email
  # @param new_address [String] the new email address the account will use
  # @return [true]
  # @note this will automatically create an alias of the old address
  def rename!(new_address)
    params = {primaryEmail: new_address}

    user_updates = directory.users.update.request_schema.new(params)

    safe_execute api_method: directory.users.update, parameters: {userKey: full_email}, body_object: user_updates

    true
  end

  # Suspend the Google Apps account
  # @return [true]
  def suspend!
    update_suspension! true
  end

  # Unsuspend the Google Apps account
  # @return [true]
  def unsuspend!
    update_suspension! false
  end

  # Delete the Google Apps account
  # @return [true]
  def delete!
    safe_execute api_method: directory.users.delete, parameters: {userKey: email}

    true
  end

  # Join the Google Apps account to a Google group
  # @param group [String] the name of the group to join
  # @param role [String] the role the user should have in the group
  # @return [Object]
  def join!(group, role = 'MEMBER')
    return false if exists_in_group?(group)

    full_group = GoogleAccount.group_to_email(group)
    params = {email: full_email, role: role}

    new_member = directory.members.insert.request_schema.new(params)

    safe_execute api_method: directory.members.insert, parameters: {groupKey: full_group}, body_object: new_member

    true
  end

  # Make the Google Apps account leave a Google group
  # @param group [String] the name of the group to leave
  # @return [Object]
  def leave!(group)
    return false unless exists_in_group?(group)

    full_group = GoogleAccount.group_to_email(group)
    safe_execute api_method: directory.members.delete, parameters: {groupKey: full_group, memberKey: full_email}

    true
  end

  # Gets a all Google Apps accounts
  # @return [Array<Google::APIClient::Schema::Admin::DirectoryV1::User>]
  def self.all
    return [] unless Enabled.third_party?

    page_token = nil
    all_emails = []

    loop do
      result = execute(
        api_method: directory.users.list,
        parameters: {
          domain: Settings.google.domain,
          fields: 'nextPageToken,users(aliases,creationTime,isAdmin,primaryEmail,suspended)',
          maxResults: 500,
          pageToken: page_token
        }
      )

      result.data.users.each do |user|
        all_emails << user
      end

      break unless page_token = result.next_page_token
    end

    all_emails
  end

  # Gets a list of accounts that have never been active
  # @note The usage report from Google isn't available up to the minute so it's
  #   always best to check GoogleAccount#never_active? too
  # @return [Array<String>] email addresses of those who have never been active
  def self.never_active
    return [] unless Enabled.third_party?

    page_token = nil
    never_active_emails = []

    loop do
      result = execute(
        api_method: reports.user_usage_report.get,
        parameters: {
          userKey: 'all',
          date: Settings.google.usage_report.days_ago.days.ago.to_date.to_s,
          filters: "accounts:last_login_time==#{ZERO_DATE},accounts:is_disabled==false",
          parameters: 'accounts:last_login_time',
          fields: 'nextPageToken,usageReports(entity/userEmail,parameters)',
          pageToken: page_token
        }
      )

      result.data.usage_reports.each do |report|
        never_active_emails << report.entity.user_email
      end

      break unless page_token = result.next_page_token
    end

    never_active_emails
  end

  # Gets a list of accounts that have become inactive
  # @note See the settings for the length of time until an account is considered
  #   to be inactive
  # @note The usage report from google isn't available up to the minute so it's
  #   always best to check GoogleAccount#never_active? too
  # @return [Array<String>] email addresses of those who are inactive
  def self.inactive
    return [] unless Enabled.third_party?

    page_token = nil
    inactive_emails = []

    loop do
      inactive_date = (Time.now - Settings.deprovisioning.inactive_after)

      result = execute(
        api_method: reports.user_usage_report.get,
        parameters: {
          userKey: 'all',
          date: Settings.google.usage_report.days_ago.days.ago.to_date.to_s,
          filters: "accounts:last_login_time<#{inactive_date.iso8601},accounts:last_login_time>#{ZERO_DATE},accounts:is_disabled==false",
          parameters: 'accounts:last_login_time',
          fields: 'nextPageToken,usageReports(entity/userEmail,parameters)',
          pageToken: page_token
        }
      )

      result.data.usage_reports.each do |report|
        last_login = report.parameters.find{|p| p.name = 'accounts:last_login_time'}.datetime_value
        # It shouldn't be necessary to recheck the last_login here but better safe than sorry
        if last_login < inactive_date
          inactive_emails << report.entity.user_email
        end
      end

      break unless page_token = result.next_page_token
    end

    inactive_emails
  end

  # Convert the local part of the email to a full email address
  # @note if the email is already a full email address, it will be returned
  #   unchanged
  # @param email [String] the local part of or full email adddress
  # @return [String] The full email address with domain part
  def self.full_email(email)
    if email.include? '@'
      email
    else
      "#{email}@#{Settings.google.domain}"
    end
  end

  # Google repesents the group by it's email address but Trogdir just uses a
  #   name. This method will convert the group name to an email address.
  # @param group_name [String] The name of the group from Trogdir
  # @return [String] The full email address of the group
  def self.group_to_email(group_name)
    full_email(group_name.to_s.downcase.gsub(/[^a-z0-9]+/, '.'))
  end

  private

  # The full email address of the Google account
  # @return [String] a full email address including the domain part
  def full_email
    GoogleAccount.full_email(email)
  end

  # Does the email account actually exist?
  # @note opposite of available?
  # @see #available?
  def exists?
    return false if data.nil?

    data.emails.map{|e| e['address']}.include? full_email
  end

  def exists_in_group?(group)
    full_group = GoogleAccount.group_to_email(group)

    result = execute(api_method: directory.groups.list, parameters: {userKey: full_email} )
    result.data.groups.any? { |g| g.email == full_group }
  end

  # The date and time of the last login
  # @note currently this only includes logins to the web interface
  # @return [DateTime]
  # @return [nil] if never logged in
  def last_login
    return nil if data.nil?

    data['lastLoginTime'].to_i == 0 ? nil : data['lastLoginTime']
  end

  # Update a Google Apps account to be either active or suspended
  # @return [true]
  # @see #suspend!
  # @see #unsuspend!
  def update_suspension!(suspend = true)
    user_updates = directory.users.update.request_schema.new(suspended: suspend)

    safe_execute api_method: directory.users.update, parameters: {userKey: full_email}, body_object: user_updates

    true
  end

  # An wrapper of sorts for making API calls to Google.
  #   OAuth authentication is handled here.
  # @return [Google::APIClient]
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

  # Instance method wrapper for the api class method
  # @see .api
  def api
    return @api unless @api.nil?

    @api = self.class.api
  end

  # Execute an operation against the Google Apps API
  # @param argument_hash [Hash] A specially formatted hash to send to Google
  # @return [Google::APIClient::Result]
  def self.execute(argument_hash)
    return nil unless Enabled.third_party?

    result = api.execute(argument_hash)
    raise GoogleAppsAPIError,  result.data['error']['message'] unless result.success?
    result
  end

  # For use with potentially destructive operations against the Google API.
  #   If third-party APIs are disabled, logs the fact that it would have made a
  #   change, otherwise it will call {#execute}.
  # @param argument_hash [Hash] A specially formatted hash to send to Google
  # @return [Google::APIClient::Result]
  # @return [true] when third-party APIs are disabled
  def safe_execute(argument_hash)
    if Enabled.write_to_third_party?
      execute(argument_hash)
    else
      Log.info "Would have called the Google API with #{argument_hash.inspect}"
    end
  end

  # A wrapper around the {.execute} class method
  # @param argument_hash [Hash] A specially formatted hash to send to Google
  # @return [Google::APIClient::Result]
  # @see .execute
  def execute(argument_hash)
    self.class.execute(argument_hash)
  end

  # Gets a Reports API object from Google for use with the {#execute} method
  # @return [Google::APIClient::API]
  def self.reports
    api.discovered_api('admin', 'reports_v1')
  end

  # Gets a Directory API object from Google for use with the {#execute} method
  # @return [Google::APIClient::API]
  def self.directory
    api.discovered_api('admin', 'directory_v1')
  end

  # A wrapper around {.directory}
  # @return [Google::APIClient::API]
  def directory
    @directory ||= self.class.directory
  end

  # An account data hash from the Google API
  # @return [Hash]
  def data
    @data ||= (
      begin
        result = execute(
          api_method: directory.users.get,
          # This will find by primary email or aliases according to Google's documentation
          parameters: {userKey: full_email}
        )

        result.try(:data)
      rescue GoogleAppsAPIError
        nil
      end
    )
  end

  def self.to_google_params(params)
    def self.map_it(hash, mappings)
      sliced_hash = hash.slice(*mappings.keys)
      Hash[sliced_hash.map {|k, v| [mappings[k], v] }]
    end

    # Our style is exclude = true. Google's is include = true. So we need to invert the value.
    params[:privacy] = !params[:privacy] if params.has_key? :privacy

    google_params = map_it(params,
      'address' => :primaryEmail,
      'password' => :password,
      'privacy' => :includeInGlobalAddressList,
      'org_unit_path' => :orgUnitPath
    )

    name_params = map_it(params, 'first_name' => :givenName, 'last_name' => :familyName)
    google_params[:name] = name_params if name_params.any?

    org_params = map_it(params, 'department' => :department, 'title' => :title)
    google_params[:organizations] = [org_params] if org_params.any?

    google_params
  end

  # Generates a random password for use as a temporary account password
  # @return [String]
  def self.random_password
    rand(36**rand(16..42)).to_s(36)
  end
end
