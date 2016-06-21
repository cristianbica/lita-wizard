require "spec_helper"

describe Lita::Extensions::Wizard, lita: true do
  let(:robot) { Lita::Robot.new(registry) }
  let(:user) { Lita::User.create(42, name: "User") }
  let(:room) { Lita::Room.create_or_update("#a", name: "#a") }
  let(:message) { Lita::Message.new(robot, "test", Lita::Source.new(user: user, room: room, private_message: false)) }
  let(:route) do
    Lita::Handler::ChatRouter::Route.new.tap do |route|
      route.extensions = {}
    end
  end
  let(:payload) do
    {
      robot: robot,
      message: message,
      route: route
    }
  end

  it "should stop if message has already been processed" do
    message.extensions[:processed_by_wizard] = true
    expect(message.extensions).to receive(:[]=).never
    described_class.call(payload)
  end

  it "should mark the message as processed" do
    expect(message.extensions).to receive(:[]=).with(:processed_by_wizard, true)
    described_class.call(payload)
  end

  it "should check if the message is private" do
    expect(message).to receive(:private_message?)
    described_class.call(payload)
  end

  it "shouldn't check if the user has a pending message if the message is public" do
    allow(message).to receive(:private_message?).and_return(false)
    expect(Lita::Wizard).to receive(:pending_wizard?).never
    described_class.call(payload)
  end

  it "should check if the user has a pending message" do
    allow(message).to receive(:private_message?).and_return(true)
    expect(Lita::Wizard).to receive(:pending_wizard?)
    described_class.call(payload)
  end

  it "try to handle the message if private message and has pending wizard" do
    allow(message).to receive(:private_message?).and_return(true)
    allow(Lita::Wizard).to receive(:pending_wizard?).and_return(true)
    expect(Lita::Wizard).to receive(:handle_message)
    described_class.call(payload)
  end

  it "should return false if dummy route matched" do
    route.extensions[:dummy] = true
    expect(described_class.call(payload)).to be_falsey
  end

  it "should return true if dummy route didn't match" do
    expect(described_class.call(payload)).to be_truthy
  end
end
