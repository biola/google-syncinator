module ServiceObjects
  class TrogdirAPIError < StandardError; end

  class Base
    attr_reader :change

    def initialize(change)
      @change = change
    end

    # return value: should be nil if nothing is done or a symbol of action taken
    def call
      raise NotImplementedError, 'Override this method in child classes'
    end

    # return value: true/false
    def ignore?
      raise NotImplementedError, 'Override this method in child classes'
    end

    def self.ignore?(change)
      self.new(change).ignore?
    end
  end
end
