require 'ostruct'

class Lita::Wizard

  attr_accessor :id, :robot, :message, :user_id, :current_step_index, :values, :meta

  def initialize(robot, message, data = {})
    @id = data['id'] || SecureRandom.hex(3)
    @robot = robot
    @message = message
    @user_id = message.user.id
    @current_step_index = (data['current_step_index'] || -1).to_i
    @values = data['values'] || []
    @meta = data['meta']
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
      message = step[:label]
      message =  "#{message} (Write done when finished)" if step[:multiline]
      send_message message
    else
      advance
    end
  end

  def handle_message
    if message.body == "abort"
      send_message "Aborting. Resume your normal operations"
      abort_wizard
      destroy
    elsif step.nil?
      send_message "Some error occured. Aborting."
      destroy
    elsif message.body == "done" && step[:multiline]
      save
      advance
    elsif valid_response?
      if step[:multiline]
        values[current_step_index] ||= ""
        values[current_step_index] << "\n"
        values[current_step_index] << message.body
        values[current_step_index].strip!
        save
      else
        values[current_step_index] = message.body
        save
        advance
      end
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
      'values' => values,
      'meta' => meta
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

  def abort_wizard
  end

  def finish_wizard
  end

  def send_message(body)
    message.reply body
  end

  class << self

    def start(robot, message, meta = {})
      return false if pending_wizard?(message.user.id)
      wizard = new(robot, message, 'meta' => meta)
      wizard.advance
      true
    end

    def handle_message(robot, message)
      return false unless pending_wizard?(message.user.id)
      wizard = restore(robot, message)
      if wizard
        wizard.handle_message
        return true
      end
      false
    end

    def restore(message)
      data = MultiJson.load(Lita.redis["pending-wizard-#{message.user.id.downcase}"])
      klass = data['class'].safe_constantize
      klass.new(robot, message, data)
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
