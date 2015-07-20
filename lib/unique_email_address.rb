class UniqueEmailAddress
  PAD_NUMBER_TO = 3

  attr_reader :options

  # Options should be an array of email addresses without the "@" or domain
  def initialize(options)
    raise ArgumentError, 'options must be an Array' unless options.is_a? Enumerable

    @options = options
  end

  def best
    # Grab the first one that's available
    best = options.find do |email|
      # TODO: For now we're checking Google too to be safe. But when all emails are in university_emails, that won't be necessary
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
