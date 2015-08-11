module Workers
  module Deprovisioning
    # Base class meant to be inherited by all deprovisioning workers
    class Base
      # Finds a `DeprovisionSchedule` by it's ID
      # @param id [String] `DeprovisionSchedule` ID
      # @return [DeprovisionSchedule] the `DeprovisionSchedule` matching the provided ID
      def find_schedule(id)
        object_id = BSON::ObjectId.from_string id.to_s
        class_action = self.class.to_s.demodulize.underscore.to_sym # law suit?

        email = UniversityEmail.find_by('deprovision_schedules._id' => object_id)
        email.deprovision_schedules.find_by(action: class_action, _id: object_id)
      end
    end
  end
end
