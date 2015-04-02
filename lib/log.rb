module Log
  def self.method_missing(meth, *args, &block)
    if logger.respond_to? meth
      logger.send meth, *args, &block
    else
      super
    end
  end

  private

  def self.logger
    @logger ||= Logger.new(log_file).tap do |logger|
      logger.formatter = Logger::Formatter.new
    end
  end

  def self.log_file
    file = File.expand_path('../../log/output.log', __FILE__)
    dir = File.dirname(file)

    Dir.mkdir(dir) unless Dir.exists?(dir)

    file
  end
end
