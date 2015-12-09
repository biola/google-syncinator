# Version 1 of the Deprovision Schedules Grape API
class API::V1::DeprovisionSchedulesAPI < Grape::API
  resource :deprovision_schedules do
    before do
      @email = UniversityEmail.find_by(id: params[:email_id])
    end

    desc 'Create a deprovision schedule'
    params do
      requires :action, type: String
      requires :scheduled_for, type: DateTime
      optional :reason, type: String
    end
    post do
      args = params.slice(:action, :scheduled_for, :reason).to_h
      deprovision_schedule = @email.deprovision_schedules.build args
      deprovision_schedule.save_and_schedule!

      present deprovision_schedule, with: API::V1::DeprovisionScheduleEntity
    end

    desc 'Update a deprovision schedule'
    params do
      # There shouldn't be any reason to update a schedule other than to cancel it
      requires :canceled, type: Boolean
    end
    put ':deprovision_schedule_id' do
      raise ArgumentError, 'Cannot uncancel scheduled deprovisions' if params[:canceled] != true

      deprovision_schedule = @email.deprovision_schedules.find(params[:deprovision_schedule_id])
      deprovision_schedule.cancel!

      present deprovision_schedule, with: API::V1::DeprovisionScheduleEntity
    end

    desc 'Delete a deprovision schedule'
    delete ':deprovision_schedule_id' do
      deprovision_schedule = @email.deprovision_schedules.find(params[:deprovision_schedule_id])

      deprovision_schedule.cancel_and_destroy!

      present deprovision_schedule, with: API::V1::DeprovisionScheduleEntity
    end
  end
end
