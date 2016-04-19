module ServiceObjects
  # Exception for when an error occurs with Trogdir
  class TrogdirAPIError < StandardError; end

  # A subclass to be inherited by all service objects
  class Base
    # @!attribute [r] change
    #  The TrogdirChange that the object was initialized with
    attr_reader :change

    # @param change [TrogdirChange] The `TrogdirChange` that the service object should be run against
    def initialize(change)
      @change = change
    end

    # @abstract Subclass and override {#call} to implement
    # Run the service object logic
    # @return [Symbol] if action is taken
    # @return [nil] if nothing is done
    def call
      raise NotImplementedError, 'Override this method in child classes'
    end

    # Whether on not this service object should be run against the `trogdir_change`
    # @abstract Subclass and override {#ignore?} to implement
    # @return [Boolean]
    def ignore?
      raise NotImplementedError, 'Override this method in child classes'
    end

    # A shortcut to ServicObject.new([change]).ignore?
    # @see #ignore?
    def self.ignore?(change)
      self.new(change).ignore?
    end

    protected

    # The Google account associated with the person being changed
    # @return [GoogleAccount]
    def google_account
      @google_account ||= GoogleAccount.new(change.university_email)
    end
  end
end
