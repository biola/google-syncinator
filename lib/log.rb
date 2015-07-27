module Log
  LEVELS = [:debug, :info, :warn, :error, :fatal]

  LEVELS.each do |meth|
    define_singleton_method(meth) do |*args|
      args[0] = "DRY RUN: #{args[0]}" if Settings.dry_run?

      logger.send(meth, *args)
    end
  end

  def self.method_missing(meth, *args, &block)
    if logger.respond_to? meth
      logger.send meth, *args, &block
    else
      super
    end
  end

  def self.respond_to?(meth)
    # TODO
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
