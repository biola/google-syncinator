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

  def affiliations
    all_attrs['affiliations']
  end

  def university_email_exists?
    all_attrs['emails'].any? { |email| email['type'] == 'university' }
  end

  def affiliation_added?
    person? && (create? || update?) && affiliations_changed?
  end

  private

  def person?
    scope == 'person'
  end

  def create?
    hash['action'] == 'create'
  end

  def update?
    hash['action'] == 'update'
  end

  def affiliations_changed?
    modified.has_key?('affiliations')
  end

  def all_attrs
    hash['all_attributes']
  end
end
