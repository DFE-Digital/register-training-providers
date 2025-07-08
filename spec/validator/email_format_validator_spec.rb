require "rails_helper"

RSpec.describe EmailFormatValidator do
  let(:record) { double("Record", email:, errors:) }
  let(:errors) { double("Errors") }
  let(:validator) { described_class.new(record) }

  describe "#validate" do
    subject { validator.validate }

    context "when the email is valid" do
      let(:email) { "valid@example.com" }

      it "does not add an error to the record" do
        allow(errors).to receive(:add)
        subject
        expect(errors).not_to have_received(:add)
      end
    end

    context "when the email is invalid due to regex" do
      let(:email) { "invalid@domain..com" }

      it "adds an error to the record" do
        allow(errors).to receive(:add)
        subject
        expect(errors).to have_received(:add)
        .with(:email,
              "Enter an email address in the correct format, like name@example.com")
      end
    end

    context "when the email is too long" do
      let(:email) { "#{'a' * 321}@example.com" }

      it "adds an error to the record" do
        allow(errors).to receive(:add)
        subject
        expect(errors).to have_received(:add)
        .with(:email,
              "Enter an email address in the correct format, like name@example.com")
      end
    end

    context "when the email has consecutive periods" do
      let(:email) { "user..name@example.com" }

      it "adds an error to the record" do
        allow(errors).to receive(:add)
        subject
        expect(errors).to have_received(:add)
        .with(:email,
              "Enter an email address in the correct format, like name@example.com")
      end
    end

    context "when the hostname is too long" do
      let(:email) { "user@#{'a' * 254}.com" }

      it "adds an error to the record" do
        allow(errors).to receive(:add)
        subject
        expect(errors).to have_received(:add)
        .with(:email,
              "Enter an email address in the correct format, like name@example.com")
      end
    end

    context "when the hostname part is too long" do
      let(:email) { "user@a#{'a' * 64}.com" }

      it "adds an error to the record" do
        allow(errors).to receive(:add)
        subject
        expect(errors).to have_received(:add)
        .with(:email,
              "Enter an email address in the correct format, like name@example.com")
      end
    end

    context "when the email has invalid hostname parts" do
      let(:email) { "user@invalid_part@domain.com" }

      it "adds an error to the record" do
        allow(errors).to receive(:add)
        subject
        expect(errors).to have_received(:add)
        .with(:email,
              "Enter an email address in the correct format, like name@example.com")
      end
    end

    context "when the email has a valid TLD" do
      let(:email) { "user@domain.co" }

      it "does not add an error to the record" do
        allow(errors).to receive(:add)
        subject
        expect(errors).not_to have_received(:add)
      end
    end

    context "when the email has an invalid TLD" do
      let(:email) { "user@domain.invalid.123" }

      it "adds an error to the record" do
        allow(errors).to receive(:add)
        subject
        expect(errors).to have_received(:add)
        .with(:email,
              "Enter an email address in the correct format, like name@example.com")
      end
    end
  end
end
