class EmailAddressOptions
  SEPARATOR = '.'

  attr_reader :affiliations, :preferred_name, :first_name, :middle_name, :last_name

  def initialize(affiliations, preferred_name, first_name, middle_name, last_name)
    @affiliations = affiliations
    @preferred_name = preferred_name.to_s.strip.empty? ? first_name : preferred_name
    @first_name = first_name
    @middle_name = middle_name
    @last_name = last_name
  end

  # alumnus, accepted student, non-banner alumnus don't get emails created
  def to_a
    return [] unless self.class.allowed?(affiliations)
    options = []

    if self.class.employeeish?(affiliations)
      options << build_address(preferred_name, last_name)
      options << build_address(first_name, last_name)
      options << build_address(preferred_name, middle_initial, last_name)
      options << build_address(first_name, middle_initial, last_name)
      options << build_address(preferred_name, middle_name, last_name)
      options << build_address(first_name, middle_name, last_name)
    elsif self.class.studentish?(affiliations)
      options << build_address(preferred_name, middle_initial, last_name)
      options << build_address(first_name, middle_initial, last_name)
      options << build_address(preferred_name, middle_name, last_name)
      options << build_address(first_name, middle_name, last_name)
      # NOTE: build_address will reject any blank parts.
      #       So if they have no middlename they'll get a first.last address anyway.
    end

    options.uniq
  end

  # Must have an email address
  def self.required?(affiliations)
    (affiliations & Settings.affiliations.email_required).any?
  end

  # Can have an email address, but it's not required
  def self.not_required?(affiliations)
    !required?(affiliations) && (affiliations & Settings.affiliations.email_allowed).any?
  end

  # Is allowed to have an email address
  def self.allowed?(affiliations)
    employeeish?(affiliations) || studentish?(affiliations) || not_required?(affiliations)
  end

  private

  def middle_initial
    middle_name.to_s[0]
  end

  def build_address(*parts)
    parts.map(&:to_s).map(&:downcase).map(&:strip).map{|p| p.gsub(/[^a-z\._-]/, '')}.reject(&:empty?).join(SEPARATOR)
  end

  def self.employeeish?(affiliations)
    (affiliations & Settings.affiliations.employeeish).any?
  end

  def self.studentish?(affiliations)
    (affiliations & Settings.affiliations.studentish).any?
  end
end
