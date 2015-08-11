# Utility module to simplify writing to the log
module Log
  # The debug levels available through this module
  LEVELS = [:debug, :info, :warn, :error, :fatal]

  # @!method debug(message)
  #   Log a debug message to the log file
  #   @param message [String] the debug message to log
  #   @return [true]

  # @!method info(message)
  #   Log a info message to the log file
  #   @param message [String] the info message to log
  #   @return [true]

  # @!method warn(message)
  #   Log a warning message to the log file
  #   @param message [String] the warning message to log
  #   @return [true]

  # @!method error(message)
  #   Log a error message to the log file
  #   @param message [String] the error message to log
  #   @return [true]

  # @!method fatal(message)
  #   Log a fatal message to the log file
  #   @param message [String] the fatal message to log
  #   @return [true]
  LEVELS.each do |level|
    define_singleton_method(level) do |message|
      message = "DRY RUN: #{message}" if Settings.dry_run?

      logger.send(level, message)
    end
  end

  # Calls methods on {.logger} if it responds to them
  # @return [Object]
  def self.method_missing(meth, *args, &block)
    if logger.respond_to? meth
      logger.send meth, *args, &block
    else
      super
    end
  end

  # Does this object respond to the given method
  def self.respond_to?(meth)
    # TODO: implement this
    super
  end

  private

  def self.logger
    @logger ||= Logger.new(log_file).tap do |logger|
      logger.formatter = Logger::Formatter.new
    end
  end

  def self.log_file
    file = File.expand_path("../../log/#{GoogleSyncinator.environment}.log", __FILE__)
    dir = File.dirname(file)

    Dir.mkdir(dir) unless Dir.exists?(dir)

    file
  end
end
