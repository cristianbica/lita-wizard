require 'ostruct'

class Lita::Wizard

  attr_accessor :id, :message, :user_id, :current_step_index, :values

  def initialize(message, data = {})
    @id = data['id'] || SecureRandom.hex(3)
    @message = message
    @user_id = message.user.id
    @current_step_index = (data['current_step_index'] || -1).to_i
    @values = data['values'] || []
  end

  def advance
    self.current_step_index += 1
    save
    if final_step?
      send_message final_message
      finish_wizard
      destroy
    elsif run_current_step?
      send_message initial_message if current_step_index == 0
      send_message step[:label]
    else
      advance
    end
  end

  def handle_message
    if message.body == "abort"
      send_message "Aborting. Resume your normal operations"
      destroy
    elsif step.nil?
      send_message "Some error occured. Aborting."
      destroy
    elsif valid_response?
      values[current_step_index] = message.body
      save
      advance
    else
      send_message @error_message
    end
  end

  def save
    Lita.redis["pending-wizard-#{user_id.downcase}"] = to_json
  end

  def destroy
    Lita.redis.del "pending-wizard-#{user_id.downcase}"
  end

  def to_json
    MultiJson.dump(as_json)
  end

  def as_json
    {
      'class' => self.class.name,
      'id' => id,
      'user_id' => user_id,
      'current_step_index' => current_step_index,
      'values' => values
    }
  end

  def step
    steps[current_step_index]
  end

  def steps
    self.class.steps
  end

  def run_current_step?
    step[:if].nil? || instance_eval(&step[:if])
  end

  def final_step?
    current_step_index == steps.size
  end

  def value_for(step_name)
    values[step_index(step_name)]
  end

  def step_index(step_name)
    steps.index { |step| step.name == step_name }
  end

  def valid_response?
    if step[:validate] && !step[:validate].match(message.body)
      @error_message = 'Invalid format'
      false
    elsif step[:options] && !step[:options].include?(message.body)
      @error_message = "Invalid response. Valid options: #{step[:options].join(', ')}"
      false
    else
      true
    end
  end

  def initial_message
    "Great! I'm going to ask you some questions. During this time I cannot take regular commands. " \
    "You can abort at any time by writing abort"
  end

  def final_message
    "You're done!"
  end

  def finish_wizard
  end

  def send_message(body)
    message.reply body
  end

  class << self

    def start(message)
      Lita.logger.debug "Starting wizard for user #{message.user.id} with message #{message.body}"
      wizard = new(message)
      wizard.advance
    end

    def handle_message(message)
      Lita.logger.debug "Trying to continue wizard for user #{message.user.id} with message #{message.body}"
      return false unless pending_wizard?(message.user.id)
      Lita.logger.debug "User has a pending wizard. Restoring ..."
      wizard = restore(message)
      Lita.logger.debug "Restored: #{wizard.inspect}"
      if wizard
        wizard.handle_message
        return true
      end
      false
    end

    def restore(message)
      data = MultiJson.load(Lita.redis["pending-wizard-#{message.user.id.downcase}"])
      klass = data['class'].safe_constantize
      klass.new(message, data)
    rescue
      nil
    end

    def step(name, options = {})
      steps << OpenStruct.new(options.merge(name: name))
    end

    def steps
      @steps ||= []
    end

    def pending_wizard?(user_id)
      Lita.redis["pending-wizard-#{user_id.downcase}"]
    end
  end
end
