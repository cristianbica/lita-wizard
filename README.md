# lita-wizard

[![Build Status](https://travis-ci.org/cristianbica/lita-wizard.png?branch=master)](https://travis-ci.org/cristianbica/lita-wizard)
[![Coverage Status](https://coveralls.io/repos/cristianbica/lita-wizard/badge.png)](https://coveralls.io/r/cristianbica/lita-wizard)

A lita extension to build wizards (surveys, standups, etc). You can instruct your chat bot to ask several questions, validate responses.

## Installation

Add lita-wizard to your Lita plugin's gemspec:

``` ruby
spec.add_runtime_dependency "lita-wizard"
```

## Usage

Create a subclass of `Lita::Wizard`

``` ruby
class MyWizard

  # provide the wizard steps
  step :name, label: "Your name:"
  step :bio, label: "Tell me something about yourself:", multiline: true
  step :lang, label: "What's your preferred programming language?", options: %w(ruby php)
  step :years, label: "For how many years you're a programmer?", validate: /\d+/
  step :really, label: "Really?", options: %w(yes no), if: ->(wizard) { value_for(:years).to_i > 15 }

  # or you can have dynamic wizard steps
  
  def steps
    # return an array of objects responding to the following methods:
    # name: a string / symbol
    # lable: a string
    # multiline: boolean
    # (optional) validate: regexp
    # (optional) options: array
    # (optional) if: a proc
  end

  # you can override the following methods to customize the messages

  def initial_message
    "Great! I'm going to ask you some questions. During this time I cannot take regular commands. " \
    "You can abort at any time by writing abort"
  end

  def abort_message
    "Aborting. Resume your normal operations"
  end

  def final_message
    "You're done!"
  end

  # You can implement the following methods to customize the wizard behaviour.
  # The wizard has an instance method `meta` which contains some data you
  # set when starting the wizard

  def start_wizard
  end

  def abort_wizard
  end

  def finish_wizard
  end

end
```

In your handler call `start_wizard` to initialize the process


``` ruby
route /^some command$/, :a_callback

def a_callback(request)
  start_wizard(Mywizard, request.message, some_data: 1, other_data: 2)
end
```

## Contributing

1. Fork it ( https://github.com/cristianbica/lita-wizard/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request


