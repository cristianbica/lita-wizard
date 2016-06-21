require "spec_helper"

describe Lita::Handlers::Wizard, lita: true, lita_handler: true do

  before do
    robot.registry.register_hook(:validate_route, Lita::Extensions::Wizard)
  end

  def store_wizard(data = {})
    data = data.merge(class: "TestWizard")
    Lita.redis["pending-wizard-1"] = data.to_json
  end

  it "should ignore messages if no pending wizard" do
    send_message("test message", privately: true)
    expect(replies).to be_empty
  end

  it "should reply with the initial message if it's the first step" do
    message = Lita::Message.new(robot, "test", source)
    TestWizard.start(robot, message)
    expect(replies.first).to eq("initial message")
  end

  it "should call the start_wizard method if it's the first step" do
    message = Lita::Message.new(robot, "test", source)
    expect_any_instance_of(TestWizard).to receive(:start_wizard)
    TestWizard.start(robot, message)
  end

  it "should reply with the first question when started the wizard" do
    message = Lita::Message.new(robot, "test", source)
    TestWizard.start(robot, message)
    expect(replies.last).to eq("step one:")
  end


  it "should accept the answer of the first question" do
    message = Lita::Message.new(robot, "test", source)
    TestWizard.start(robot, message)
    send_message("response", privately: true)
    expect(replies.last).to match /^step two/
  end

  it "should accept the answer for a single message question" do
    store_wizard(current_step_index: 0)
    send_message("response-one", privately: true)
    expect(replies.last).to match /^step two/
  end

  it "should accept the answer for a multiline message question" do
    store_wizard(current_step_index: 1)
    send_message("response-two line 1", privately: true)
    send_message("response-two line 2", privately: true)
    send_message("done", privately: true)
    expect(replies.last).to match /^step three/
  end

  it "should skip question which return false from the if block" do
    store_wizard(current_step_index: 2)
    send_message("response-three", privately: true)
    expect(replies.last).to match /^step five/
  end

  it "should not accept answer not matching the provided regexp" do
    store_wizard(current_step_index: 4)
    send_message("abc", privately: true)
    expect(replies.last).to match /^Invalid format/
  end

  it "should accept answer matching the provided regexp" do
    store_wizard(current_step_index: 4)
    send_message("123", privately: true)
    expect(replies.last).to match /^step six/
  end

  it "should not accept answer not in the options list" do
    store_wizard(current_step_index: 5)
    send_message("abc", privately: true)
    expect(replies.last).to match /^Invalid response/
  end

  it "should accept answer in the options list" do
    store_wizard(current_step_index: 5)
    send_message("one", privately: true)
    expect(replies.last).to match /^final message/
  end

  it "should reply with the last message when answering the last question" do
    store_wizard(current_step_index: 5)
    send_message("one", privately: true)
    expect(replies.last).to match /^final message/
  end

  it "should call the finish_wizard method when answering the last question" do
    store_wizard(current_step_index: 5)
    expect_any_instance_of(TestWizard).to receive(:finish_wizard)
    send_message("one", privately: true)
  end

  it "should abort the wizard if requested by the user" do
    store_wizard(current_step_index: 0)
    send_message("abort", privately: true)
    puts replies.inspect
    expect(Lita::Wizard.pending_wizard?("1")).to be_falsey
  end

  it "should send the abort message when aborting" do
    store_wizard(current_step_index: 0)
    send_message("abort", privately: true)
    expect(replies.last).to match /^abort message/
  end

  it "should call the abort_wizard method if requested by the user" do
    store_wizard(current_step_index: 0)
    expect_any_instance_of(TestWizard).to receive(:abort_wizard)
    send_message("abort", privately: true)
  end



end
