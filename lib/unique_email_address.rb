# Finds the best available email address from the given options that is not taken
class UniqueEmailAddress
  # If none of the options are available a number will be appended to the end of
  #   the first option. This determines what the number should be zero padded to.
  PAD_NUMBER_TO = 3

  # Email address options to check for availability
  # @return [Array<String>]
  attr_reader :options

  # @param options [Array<String>] email addresses without the "@" or domain
  def initialize(options)
    raise ArgumentError, 'options must be an Array' unless options.is_a? Enumerable

    @options = options
  end

  # Find the best available email address
  # @note If all options are taken a zero-padded number will be appended
  # @return [String] the local part of the best email 
  def best
    # Grab the first one that's available
    best = options.find do |email|
      # NOTE: For now we're checking Google too to be safe. When all emails are in university_emails, that may not be necessary
      UniversityEmail.available?(email) && GoogleAccount.new(email).available?
    end

    # If none of the options are available append a three-digit number
    while best.nil?
      i ||= 1

      options.each do |email|
        try_email = "#{email}#{i.to_s.rjust(PAD_NUMBER_TO, '0')}"

        if GoogleAccount.new(try_email).available?
          best = try_email
          break
        end
      end

      raise RuntimeError, 'loop went on for too long' if i > 500

      i += 1
    end

    best
  end
end
