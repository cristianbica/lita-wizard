module Lita
  module Handlers
    class Wizard < Handler
      route(/.*/, nil, dummy: true)

      Lita.register_handler(self)
    end
  end
end
