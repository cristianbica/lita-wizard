module Lita
  module Extensions
    class Wizard
      def self.call(payload)
        message = payload[:message]
        route = payload[:route]
        robot = payload[:robot]
        return true if message.extensions[:processed_by_wizard]
        return true unless message.private_message?
        message.extensions[:processed_by_wizard] = true
        handled = Lita::Wizard.handle_message(robot, message)
        return true if handled
        dummy = (route.extensions[:dummy] == true)
        !dummy
      end

      Lita.register_hook(:validate_route, self)
    end
  end
end
