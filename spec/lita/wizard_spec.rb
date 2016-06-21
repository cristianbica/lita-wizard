require "spec_helper"

describe Lita::Wizard, lita: true do
  let(:robot) { Lita::Robot.new(registry) }
  let(:user) { Lita::User.create(42, name: "User") }
  let(:room) { Lita::Room.create_or_update("#a", name: "#a") }
  let(:message) { Lita::Message.new(robot, "test", Lita::Source.new(user: user, room: room, private_message: false)) }

  context "starting a wizard" do
    after { Lita::Wizard.start(robot, message) }
    it "should check if a pending wizard exists for that user" do
      expect(Lita::Wizard).to receive(:pending_wizard?).with("42").and_return(true)

    end

    it "should try to start a new wizard if a pending one exists" do
      allow(Lita::Wizard).to receive(:pending_wizard?).and_return(true)
      expect(Lita::Wizard).to receive(:new).never
    end

    it "should initialize a new wizard class an advance" do
      mocked_wizard = double
      expect(mocked_wizard).to receive(:advance)
      allow(Lita::Wizard).to receive(:pending_wizard?).and_return(false)
      expect(Lita::Wizard).to receive(:new).and_return(mocked_wizard)
    end
  end

  context "handling messages" do
    after { Lita::Wizard.handle_message(robot, message) }

    it "should handle message if there isn't a pending wizard" do
      allow(Lita::Wizard).to receive(:pending_wizard?).and_return(false)
      expect(Lita::Wizard).to receive(:restore).never
    end

    it "should try to restore the wizard" do
      allow(Lita::Wizard).to receive(:pending_wizard?).and_return(true)
      expect(Lita::Wizard).to receive(:restore).once
    end

    it "should restore the wizard and forward the message to be handled" do
      allow(Lita::Wizard).to receive(:pending_wizard?).and_return(true)
      mocked_wizard = double
      expect(mocked_wizard).to receive(:handle_message)
      expect(Lita::Wizard).to receive(:restore).and_return(mocked_wizard)
    end
  end

  context "restoring wizards" do
    it "should return nil if there's no saved wizard" do
      expect(Lita::Wizard.restore(robot, message)).to be_nil
    end

    it "should return nil if data is malformed" do
      expect(Lita::Wizard.restore(robot, message)).to be_nil
    end

    it "should restore the wizard", :focus do
      data = { class: "TestWizard", arg1: "43" }
      Lita.redis["pending-wizard-42"] = data.to_json
      expect(TestWizard).to receive(:new)#.with(robot, message, data)
      Lita::Wizard.restore(robot, message)
    end
  end

  context "checking for a pending wizard" do
    it "should return true if a pending wizard was saved" do
      Lita.redis["pending-wizard-42"] = "1"
      expect(Lita::Wizard.pending_wizard?("42")).to be_truthy
    end

    it "should return false if no pending wizards saved" do
      expect(Lita::Wizard.pending_wizard?("42")).to be_falsey
    end
  end
end
