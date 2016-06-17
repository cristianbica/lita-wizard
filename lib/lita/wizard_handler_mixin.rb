module Lita
  module WizardHandlerMixin
    def start_wizard(klass, message, meta = {})
      klass.start(robot, message, meta)
    end
  end

  class Handler
    prepend WizardHandlerMixin
  end
end
