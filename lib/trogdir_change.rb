class TrogdirChange
  attr_reader :hash
  def initialize(hash)
    @hash = hash
  end

  def sync_log_id
    hash['sync_log_id']
  end

  def person_uuid
    hash['person_id']
  end

  def biola_id
    Array(all_attrs['ids']).find { |id| id['type'] == 'biola_id' }['identifier']
  end

  def preferred_name
    all_attrs['preferred_name']
  end

  def first_name
    all_attrs['first_name']
  end

  def middle_name
    all_attrs['middle_name']
  end

  def last_name
    all_attrs['last_name']
  end

  def title
    all_attrs['title']
  end

  def department
    all_attrs['department']
  end

  def affiliations
    if modified.has_key? 'affiliations'
      modified['affiliations']
    else
      all_attrs['affiliations']
    end
  end

  def privacy
    all_attrs['privacy']
  end

  def university_email
    if person?
      Array(all_attrs['emails']).find { |email| email['type'] == 'university' }['address']
    elsif email?
      all_attrs['address']
    end
  end

  def new_university_email
    modified['address']
  end

  def university_email_exists?
    Array(all_attrs['emails']).any? { |email| email['type'] == 'university' }
  end

  def affiliation_added?
    person? && (create? || update?) && affiliations_changed?
  end

  def university_email_added?
    email? && create? && all_attrs['type'] == 'university'
  end

  def account_info_updated?
    person? && (create? || update?) && (name_changed? || work_changed? || privacy_changed?)
  end

  def university_email_updated?
    email? && update? && all_attrs['type'] == 'university'
  end

  def joined_groups
    return [] unless person?
    Array(modified['groups']) - Array(original['groups'])
  end

  def left_groups
    return [] unless person?
    Array(original['groups']) - Array(modified['groups'])
  end

  private

  def person?
    hash['scope'] == 'person'
  end

  def email?
    hash['scope'] == 'email'
  end

  def create?
    hash['action'] == 'create'
  end

  def update?
    hash['action'] == 'update'
  end

  def affiliations_changed?
    changed_attrs.include?('affiliations')
  end

  def name_changed?
    changed_attrs.include?('preferred_name') || changed_attrs.include?('last_name')
  end

  def work_changed?
    changed_attrs.include?('department') || changed_attrs.include?('title')
  end

  def privacy_changed?
    changed_attrs.include? 'privacy'
  end

  def changed_attrs
    @changed_attrs ||= (original.keys + modified.keys).uniq
  end

  def original
    hash['original']
  end

  def modified
    hash['modified']
  end

  def all_attrs
    hash['all_attributes']
  end
end
