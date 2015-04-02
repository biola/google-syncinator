class EmailAddressOptions
  EMPLOYEEISH_AFFILIATIONS = ['employee', 'trustee', 'faculty', 'other', 'faculty emeritus']
  STUDENTISH_AFFILIATIONS = ['student']
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
    options = []

    if employeeish?
      options << build_address(preferred_name, last_name)
      options << build_address(first_name, last_name)
      options << build_address(preferred_name, middle_initial, last_name)
      options << build_address(first_name, middle_initial, last_name)
      options << build_address(preferred_name, middle_name, last_name)
      options << build_address(first_name, middle_name, last_name)
    elsif studentish?
      options << build_address(preferred_name, middle_initial, last_name)
      options << build_address(first_name, middle_initial, last_name)
      options << build_address(preferred_name, middle_name, last_name)
      options << build_address(first_name, middle_name, last_name)
      # NOTE: build_address will reject any blank parts.
      #       So if they have no middlename they'll get a first.last address anyway.
    end

    options.uniq
  end

  private

  def middle_initial
    middle_name.to_s[0]
  end

  def employeeish?
    (affiliations & EMPLOYEEISH_AFFILIATIONS).any?
  end

  def studentish?
    (affiliations & STUDENTISH_AFFILIATIONS).any?
  end

  def build_address(*parts)
    parts.map(&:to_s).map(&:downcase).map(&:strip).map{|p| p.gsub(/[^a-z\._-]/, '')}.reject(&:empty?).join(SEPARATOR)
  end
end
