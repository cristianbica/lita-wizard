module Lita
  module Extensions
    class Wizard
      def self.call(payload)
        message = payload[:message]
        route = payload[:route]
        robot = payload[:robot]

        # mark message as processed and return next time
        return true if message.extensions[:processed_by_wizard]
        message.extensions[:processed_by_wizard] = true

        # if private messages and user has a pending wizard handle the message
        if message.private_message? && Lita::Wizard.pending_wizard?(message.user.id)
          handled = Lita::Wizard.handle_message(robot, message)
          return true if handled
        end

        # return
        !(route.extensions[:dummy] == true)
      end

      Lita.register_hook(:validate_route, self)
    end
  end
end
