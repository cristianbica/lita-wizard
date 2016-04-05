require "lita"

Lita.load_locales Dir[File.expand_path(
  File.join("..", "..", "locales", "*.yml"), __FILE__
)]

require "lita/wizard"
require "lita/extensions/wizard"
require "lita/handlers/wizard"
require "lita/wizard_handler_mixin"
