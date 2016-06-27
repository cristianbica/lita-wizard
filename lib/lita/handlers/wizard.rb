module Lita
  module Handlers
    class Wizard < Handler

      route(/.*/, nil, dummy: true) do |response|
      end

      Lita.register_handler(self)

    end
  end
end
