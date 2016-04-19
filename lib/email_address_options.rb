# Generates possible email address combinations for a person based of the parts
#   of their full name and nickname
class EmailAddressOptions
  # Character to use to separate name parts in the email address
  SEPARATOR = '.'

  # Affiliations from Trogdir - employee, student, alumnus, etc.
  # @return [Array<String>]
  attr_reader :affiliations

  # The person's preferred name or nickname, if any
  # @return [String]
  attr_reader :preferred_name

  # The person's first name
  # @return [String]
  attr_reader :first_name

  # The person's middle name, if any
  # @return [String]
  attr_reader :middle_name

  # The person's last name
  # @return [String]
  attr_reader :last_name

  # @param affiliations [Array<String>] the person's affiliations
  # @param preferred_name [String] the person's preferred name or nickname, if any
  # @param first_name [String] the person's first name
  # @param middle_name [String] the person's middle name if any
  # @param last_name [String] the person's last name
  def initialize(affiliations, preferred_name, first_name, middle_name, last_name)
    @affiliations = affiliations
    @preferred_name = preferred_name.to_s.strip.empty? ? first_name : preferred_name
    @first_name = first_name
    @middle_name = middle_name
    @last_name = last_name
  end

  # An array of accepetable email addresses based on the person's names
  # @note This method does not check the availability of email addresses. {UniqueEmailAddress} should be used for that.
  # @note Will return an empty array array if the user is not allowed an email
  # @note Student emails usually contain the middle initial or name, employee emails don't.
  # @return [Array<String>]
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

  # Is the person required to have an email address based off their affiliations?
  # @param affiliations [Array<String>]
  # @note Typically students and employees but depends on configuration
  def self.required?(affiliations)
    (affiliations & Settings.affiliations.email_required).any?
  end

  # Is the person allowed but not required to have an email address
  # @param affiliations [Array<String>]
  # @note Typically alumni but depends on configuration
  def self.not_required?(affiliations)
    !required?(affiliations) && (affiliations & Settings.affiliations.email_allowed).any?
  end

  # Is the person required or allowed to have an email address
  # @param affiliations [Array<String>]
  # @note Typically students, employees and alumni but depends on configuration
  def self.allowed?(affiliations)
    employeeish?(affiliations) || studentish?(affiliations) || not_required?(affiliations)
  end

  private

  # First letter of their middle name, if any
  # @return [String]
  def middle_initial
    middle_name.to_s[0]
  end

  # Generate the local part of the email address
  # @return [String]
  def build_address(*parts)
    parts.map(&:to_s).map(&:downcase).map(&:strip).map{|p| p.gsub(/[^a-z\._-]/, '')}.reject(&:empty?).join(SEPARATOR)
  end

  # Does this person have any employee-like affiliations
  # @param affiliations [Array<String>]
  def self.employeeish?(affiliations)
    (affiliations & Settings.affiliations.employeeish).any?
  end

  # Does this person have any student-like affiliations
  # @param affiliations [Array<String>]
  def self.studentish?(affiliations)
    (affiliations & Settings.affiliations.studentish).any?
  end
end
