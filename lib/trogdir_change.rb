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
    all_attrs['affiliations']
  end

  def privacy
    all_attrs['privacy']
  end

  def university_email_exists?
    all_attrs['emails'].any? { |email| email['type'] == 'university' }
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
    @changed_attrs ||= (hash['original'].keys + hash['modified'].keys).uniq
  end

  def all_attrs
    hash['all_attributes']
  end
end
