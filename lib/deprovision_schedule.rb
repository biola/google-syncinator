# A record of scheuled actions on a university email. These actions include
# email notifications, suspensions, deletions and activations, or
# re-activations really, since a newly created email account doesn't have to
# be activated.
# @note The deprovisioning sidekiq workers work hand-in-hand with these to actually
#   perform the actions.
# @see Workers::Deprovisioning
class DeprovisionSchedule
  include Mongoid::Document
  include Mongoid::Timestamps

  # Valid values for the action field
  ACTIONS = [:notify_of_inactivity, :notify_of_closure, :suspend, :delete, :activate]
  # Maps action names to university email states
  # @see UniversityEmail#state
  STATE_MAP = {
    activate: :active,
    suspend: :suspended,
    delete: :deleted
  }

  # @!attribute university_email
  #   @return [UniversityEmail]
  # @!method university_email=(university_email)
  #   @param university_email [UniversityEmail]
  #   @return [UniversityEmail]
  embedded_in :university_email

  # @!attribute action
  #   @return [Symbol] the action that should be taken
  #   @note must be one of ACTIONS
  #   @see ACTIONS
  # @!method action=(action)
  #   @param action [Symbol] the action that should be taken
  #   @return [Symbol]
  field :action, type: Symbol

  # @!attribute reason
  #   @return [String] the reason the action is being scheduled
  # @!method reason=(reason)
  #   @param reason [String] the reason the action is being scheduled
  #   @return [String]
  field :reason, type: String

  # @!attribute scheduled_for
  #   @return [DateTime] when the action is scheduled for
  # @!method scheduled_for=(scheduled_for)
  #   @param scheduled_for [DateTime] when the action is scheduled for
  #   @return [DateTime]
  field :scheduled_for, type: DateTime

  # @!attribute completed_at
  #   @return [DateTime] when the action was completed
  # @!method completed_at=(completed_at)
  #  @param completed_at [DateTime] when the action was completed
  #  @return [DateTime]
  field :completed_at, type: DateTime

  # @!attribute canceled
  #   @return [Boolean] whether or not the action was canceled
  # @!method canceled=(canceled)
  #  @param canceled [Boolean] whether or not the action was canceled
  #  @return [Boolean]
  field :canceled, type: Boolean

  # @!attribute job_id
  #   @return [String] the ID of the scheduled Sidekiq job
  #   @note This can be used to cancel the job if necessary
  # @!method job_id=(job_id)
  #   @param job_id [String] the ID of the scheduled Sidekiq job
  #   @return [String]
  field :job_id, type: String

  validates :action, presence: true
  validates :scheduled_for, presence: true, unless: :completed_at?
  validates :completed_at, presence: true, unless: :scheduled_for?
  validates :action, inclusion: {in: ACTIONS}

  # Is the action still waiting to be completed
  # @return [Boolean]
  def pending?
    !(completed_at? || canceled?)
  end

  # Creates a DeprovisionSchedule and schedules the job in Sidekiq
  # @return [String, nil] Sidekiq job ID
  def save_and_schedule!
    jid = nil

    # We won't schedule this during a dry run because even though it would be safe to do now, dry_run could be off when it actually runs
    if !Settings.dry_run?
      cancel_job! if pending? && job_id?

      save!

      if pending?
        jid = worker_class.perform_at(scheduled_for, id.to_s)
        update! job_id: jid
      end
    end

    job_id
  end

  # Cancels the sidekiq worker and updates canceled attribute
  # @return [String] Sidekiq job ID
  def cancel!
    unless Settings.dry_run?
      cancel_job!
      update! canceled: true
    end

    job_id
  end

  # Cancel the sidekiq job and destroy the schedule record
  # @return [Boolean]
  def cancel_and_destroy!
    unless Settings.dry_run?
      cancel_job!
      destroy!
    end
  end

  after_save do
    if completed_at_changed? && completed_at.present?
      university_email.update state: STATE_MAP[action] unless Settings.dry_run?
    end
  end

  private

  # Get the worker class associated with this schedule's action
  # @return [Class]
  def worker_class
    Workers::Deprovisioning.const_get(action.to_s.classify)
  end

  # Cancel the associated sidekiq job
  # @return [String] sidekiq job ID
  def cancel_job!
    unless Settings.dry_run?
      Sidekiq::Status.cancel(job_id) if job_id?
    end

    job_id
  end
end
