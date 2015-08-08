module Workers
  module Deprovisioning
    class Base
      def find_schedule(id)
        object_id = BSON::ObjectId.from_string id
        class_action = self.class.to_s.demodulize.underscore.to_sym # law suit?

        email = UniversityEmail.find_by('deprovision_schedules._id' => object_id)
        email.deprovision_schedules.find_by(action: class_action, _id: object_id)
      end
    end
  end
end
