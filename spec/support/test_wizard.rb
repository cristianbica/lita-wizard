class TestWizard < Lita::Wizard

  step :one,
       label: 'step one:'

  step :two,
       label: 'step two:',
       multiline: true

  step :three,
       label: 'step three:',
       if: ->(_) { true }

  step :four,
       label: 'step four:',
       if: ->(_) { false }

  step :five,
       label: 'step five:',
       validate: /\d{3}/

  step :six,
       label: 'step six:',
       options: %w(one two)

  def initial_message
    "initial message" << super
  end

  def abort_message
    "abort message" << super
  end

  def final_message
    "final message" << super
  end

end
