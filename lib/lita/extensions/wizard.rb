module Lita
  module Extensions
    class Wizard
      attr_reader :message, :route, :robot

      def self.call(payload)
        new(payload).call
      end

      def initialize(payload)
        @message = payload[:message]
        @route = payload[:route]
        @robot = payload[:robot]
        Lita.logger.debug "Initializing Lita::Extensions::Wizard with:\nMessage: #{message.body}\nRoute: #{route.inspect}"
      end

      def call
        process_message if should_process_message?
        Lita.logger.debug "Handled by wizard: #{!!message.extensions[:handled_by_wizard]}"
        Lita.logger.debug "Dummy route: #{route.extensions[:dummy] == true}"
        ret = compute_return_value
        Lita.logger.debug "Returning #{ret.inspect}"
        ret
      end

      protected

      def process_message
        Lita.logger.debug "Processing message"
        message.extensions[:processed_by_wizard] = true
        message.extensions[:handled_by_wizard] = Lita::Wizard.handle_message(robot, message)
        Lita.logger.debug "Message processed: #{message.extensions.inspect}"
      end

      def should_process_message?
        !already_processed? && private_message? && user_has_pending_wizard?
      end

      def already_processed?
        message.extensions[:processed_by_wizard]
      end

      def private_message?
        message.private_message?
      end

      def user_has_pending_wizard?
        Lita::Wizard.pending_wizard?(message.user.id)
      end

      def compute_return_value
        if message.extensions[:handled_by_wizard]
          route.extensions[:dummy] == true
        else
          !route.extensions[:dummy]
        end
      end

      Lita.register_hook(:validate_route, self)
    end
  end
end
