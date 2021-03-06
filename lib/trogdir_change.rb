# A wrapper around a Trogdir change hash
class TrogdirChange
  # The bare change hash from Trogdir
  attr_reader :hash

  # Initialize a new TrogdirChange object
  # @param hash [Hash] a Trogdir change hash
  def initialize(hash)
    @hash = hash
  end

  # The Trogdir sync log ID
  # @return [String]
  def sync_log_id
    hash['sync_log_id']
  end

  # The Trogdir person record's UUID
  # @return [String]
  def person_uuid
    hash['person_id']
  end

  def biola_id_updated?
    biola_id? && update?
  end

  # The identifier before the change
  # @return [String] the identifier
  # @note Only works if the change is to an ID scope
  def old_id
    original['identifier']
  end

  # The identifier after the change
  # @return [String] the identifier
  # @note Only works if the change is to an ID scope
  def new_id
    modified['identifier']
  end

  # The person's preferred name
  # @return [String]
  def preferred_name
    all_attrs['preferred_name']
  end

  # The person's first name
  # @return [String]
  def first_name
    all_attrs['first_name']
  end

  # The person's middle name if any
  # @return [String, nil]
  def middle_name
    all_attrs['middle_name']
  end

  # The person's last name
  # @return [String]
  def last_name
    all_attrs['last_name']
  end

  # The affiliations before the change
  # @return [Array<String>]
  def old_affiliations
    Array(original['affiliations'])
  end

  # The affiliations after the change
  # @return [Array<String>]
  def new_affiliations
    Array(modified['affiliations'])
  end

  # The person's affiliations
  # @return [Array<String>]
  def affiliations
    if modified.has_key? 'affiliations'
      modified['affiliations']
    else
      all_attrs['affiliations']
    end
  end

  # The person's university type email address, if any
  # @return [String, nil]
  def university_email
    if person?
      Array(all_attrs['emails']).find { |email| email['type'] == 'university' }.try(:[], 'address')
    elsif email?
      all_attrs['address']
    end
  end

  # Whether or not the person has a university email address
  def university_email_exists?
    Array(all_attrs['emails']).any? { |email| email['type'] == 'university' }
  end

  # Whether or not the person's affiliations were changed
  def affiliations_changed?
    changed_attrs.include?('affiliations')
  end

  # Whether or not any affiliations were added to the person record
  def affiliation_added?
    person? && (create? || update?) && affiliations_changed? && (modified['affiliations'].to_a - original['affiliations'].to_a).any?
  end

  # Whether or not a university email was added to the person record
  def university_email_added?
    email? && create? && all_attrs['type'] == 'university'
  end

  # Whether or not any info stored in the Google Apps account was changed
  def account_info_updated?
    person? && (create? || update?) && (name_changed? || work_changed? || privacy_changed?)
  end

  # Any groups that the person joined
  # @return [Array<String>]
  def joined_groups
    return [] unless person?
    Array(modified['groups']) - Array(original['groups'])
  end

  # Any groups that the person left
  # @return [Array<String>]
  def left_groups
    return [] unless person?
    Array(original['groups']) - Array(modified['groups'])
  end

  private

  # Is a person record being changed?
  def person?
    hash['scope'] == 'person'
  end

  # Is an email record being changed?
  def email?
    hash['scope'] == 'email'
  end

  def biola_id?
    hash['scope'] == 'id' && all_attrs['type'] == 'biola_id' && changed_attrs.include?('identifier')
  end

  # Is a record being created?
  def create?
    hash['action'] == 'create'
  end

  # Is an existing record being updated?
  def update?
    hash['action'] == 'update'
  end

  # Was the person's name changed?
  def name_changed?
    changed_attrs.include?('preferred_name') || changed_attrs.include?('last_name')
  end

  # Was the person's work info changed?
  def work_changed?
    changed_attrs.include?('department') || changed_attrs.include?('title')
  end

  # Was the person's privacy setting changed?
  def privacy_changed?
    changed_attrs.include? 'privacy'
  end

  # Names of all of the attributes that were changed
  # @return [Array<String>]
  def changed_attrs
    @changed_attrs ||= (original.keys + modified.keys).uniq
  end

  # The attributes before the changed occurred
  # @return [Hash]
  def original
    hash['original']
  end

  # The attributes after the change occurred
  # @return [Hash]
  def modified
    hash['modified']
  end

  # All of the attributes for the record whether they were changed or not
  # @return [Hash]
  def all_attrs
    hash['all_attributes']
  end
end
