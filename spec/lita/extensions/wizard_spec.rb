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
  subject { described_class.new(payload) }

  context "deciding if it should process the message" do
    it "shouldn't process the message if it was already processed" do
      allow(subject).to receive(:private_message?).and_return(true)
      allow(subject).to receive(:user_has_pending_wizard?).and_return(true)
      message.extensions[:processed_by_wizard] = true
      expect(subject).to receive(:process_message).never
      subject.call
    end

    it "shouldn't process the message if it's a public message" do
      allow(subject).to receive(:already_processed?).and_return(false)
      allow(subject).to receive(:user_has_pending_wizard?).and_return(true)
      expect(subject).to receive(:process_message).never
      subject.call
    end

    it "shouldn't process the message if the user doesn't have a pending wizard" do
      allow(subject).to receive(:already_processed?).and_return(false)
      allow(subject).to receive(:private_message?).and_return(true)
      Lita::Wizard.cancel_wizard("42")
      expect(subject).to receive(:process_message).never
      subject.call
    end

    it "should process the message only once" do
      allow(subject).to receive(:private_message?).and_return(true)
      allow(subject).to receive(:user_has_pending_wizard?).and_return(true)
      expect(Lita::Wizard).to receive(:handle_message).once
      subject.call
      subject.call
    end

    it "should process the message if not processed, private message and user has pending wizard" do
      message.extensions.delete :processed_by_wizard
      message.source.private_message!
      allow(Lita::Wizard).to receive(:pending_wizard?).and_return(true)
      expect(subject).to receive(:process_message).once
      subject.call
    end
  end

  context "processing the message" do
    before { allow(subject).to receive(:should_process_message?).and_return(true) }

    it "should mark the message as processed" do
      allow(Lita::Wizard).to receive(:handle_message)
      subject.call
      expect(message.extensions[:processed_by_wizard]).to be_truthy
    end

    it "should set on the message the return value from handle_message" do
      allow(Lita::Wizard).to receive(:handle_message).and_return("42")
      subject.call
      expect(message.extensions[:handled_by_wizard]).to eq("42")
    end
  end

  context "return value" do
    it "should return true if the message is not processable for a non dummy route" do
      allow(subject).to receive(:should_process_message?).and_return(false)
      expect(subject.call).to be_truthy
    end

    it "should return false if the message is not processable for a dummy route" do
      allow(subject).to receive(:should_process_message?).and_return(false)
      route.extensions[:dummy] = true
      expect(subject.call).to be_falsey
    end

    it "should return false if called on a processable and handled message for a non dummy route" do
      message.extensions.delete :processed_by_wizard
      message.source.private_message!
      allow(Lita::Wizard).to receive(:pending_wizard?).and_return(true)
      expect(Lita::Wizard).to receive(:handle_message).once.and_return(true)
      expect(subject.call).to be_falsey
      expect(subject.call).to be_falsey
    end

    it "should return true if called on a processable and handled message for a dummy route" do
      message.extensions.delete :processed_by_wizard
      message.source.private_message!
      allow(Lita::Wizard).to receive(:pending_wizard?).and_return(true)
      expect(Lita::Wizard).to receive(:handle_message).once.and_return(true)
      route.extensions[:dummy] = true
      expect(subject.call).to be_truthy
    end

    it "should return true if the message couldn't be handled by the wizard for a non dummy route" do
      message.extensions.delete :processed_by_wizard
      message.source.private_message!
      allow(Lita::Wizard).to receive(:pending_wizard?).and_return(true)
      expect(Lita::Wizard).to receive(:handle_message).once.and_return(false)
      expect(subject.call).to be_truthy
    end

    it "should return false if the message couldn't be handled by the wizard for a dummy route" do
      message.extensions.delete :processed_by_wizard
      message.source.private_message!
      allow(Lita::Wizard).to receive(:pending_wizard?).and_return(true)
      expect(Lita::Wizard).to receive(:handle_message).once.and_return(false)
      route.extensions[:dummy] = true
      expect(subject.call).to be_falsey
    end
  end


end
