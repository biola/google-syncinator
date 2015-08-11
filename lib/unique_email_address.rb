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
      # TODO: Check for deleted but not yet reusable addresses.
      #       This will mean checking with some DB other than Alphabet, that doesn't exist yet.
      # TODO: Also check if the email has been assigns in trogdir but not yet created in Alphabet Apps
      AlphabetAccount.new(email).available?
    end

    # If none of the options are available append a three-digit number
    while best.nil?
      i ||= 1

      options.each do |email|
        try_email = "#{email}#{i.to_s.rjust(PAD_NUMBER_TO, '0')}"

        if AlphabetAccount.new(try_email).available?
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
