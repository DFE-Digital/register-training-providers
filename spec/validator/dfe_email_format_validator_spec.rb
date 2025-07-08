require "rails_helper"

RSpec.describe DfEEmailFormatValidator do
  let(:record) { double("Record", email:, errors:) }
  let(:errors) { double("Errors") }
  let(:validator) { described_class.new(record) }

  describe "#validate" do
    subject { validator.validate }

    context "when the email is valid" do
      let(:email) { "valid@education.gov.uk" }

      it "does not add an error to the record" do
        allow(errors).to receive(:add)
        subject
        expect(errors).not_to have_received(:add)
      end
    end

    context "when the email is invalid" do
      let(:email) { "invalid@badeducation.gov.uk" }

      it "adds an error to the record" do
        allow(errors).to receive(:add)
        subject
        expect(errors).to have_received(:add)
        .with(:email,
              "Enter a Department for Education email address in the correct format, like name@education.gov.uk")
      end
    end
  end
end
