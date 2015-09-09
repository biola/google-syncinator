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

  # The Biola ID number of the person
  # @return [String]
  def biola_id
    Array(all_attrs['ids']).find { |id| id['type'] == 'biola_id' }['identifier']
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

  # The person's title
  # @return [String, nil]
  def title
    all_attrs['title']
  end

  # The person's department
  # @return [String, nil]
  def department
    all_attrs['department']
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

  # Whether or not the person has chose to have FERPA privacy
  # @return [Boolean]
  def privacy
    all_attrs['privacy']
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

  # The person's new university email address if it was changed
  # @return [String, nil]
  def new_university_email
    modified['address']
  end

  # The person's old university email address if it was changed
  # @return [String, nil]
  def old_university_email
    original['address']
  end

  # Whether or not the person has a university email address
  def university_email_exists?
    Array(all_attrs['emails']).any? { |email| email['type'] == 'university' }
  end

  # Whether or not the person's affiliations were changed
  def affiliations_changed?
    changed_attrs.include?('affiliations')
  end

  # Whether or not any affiliatons were added to the person record
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

  # Whether or not the university email was changed
  def university_email_updated?
    email? && update? && all_attrs['type'] == 'university'
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
