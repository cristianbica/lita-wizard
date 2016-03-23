module Lita
  module Extensions
    class Wizard
      def self.call(payload)
        Lita.logger.debug "Lita::Wizard intercepted: #{payload.inspect}"
        message = payload[:message]
        route = payload[:route]
        return true if message.extensions[:processed_by_wizard]
        message.extensions[:processed_by_wizard] = true
        handled = Lita::Wizard.handle_message(message)
        dummy = (route.extensions[:dummy] == true)
        return true if handled
        !dummy
      end

      Lita.register_hook(:validate_route, self)
    end
  end
end
