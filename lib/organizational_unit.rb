# Methods concerned with Google Apps' organizational units
module OrganizationalUnit
  # The orgUnitPath to assign if no matches are found
  DEFAULT_ORG_UNIT = '/'

  # Get the orgUnitPath for a person or an array of affiliations
  # @param person_or_affiliations [Array<String>, #affiliations]
  # @return [String] a matching orgUnitPath
  def self.path_for(affiliations)
    affiliations = affiliations.affiliations if affiliations.respond_to? :affiliations

    Settings.organizational_units.each do |org_unit, affils|
      return org_unit.to_s if (affiliations.to_a & affils).any?
    end

    DEFAULT_ORG_UNIT
  end
end
