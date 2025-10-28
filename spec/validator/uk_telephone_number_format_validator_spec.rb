require "rails_helper"

RSpec.describe UkTelephoneNumberFormatValidator do
  let(:record) { double("Record", telephone_number:, errors:) }
  let(:errors) { double("Errors") }
  let(:validator) { described_class.new(record) }

  describe "#validate" do
    subject { validator.validate }

    context "when the email is valid" do
      let(:telephone_number) { "+44 7121 121 121" }

      it "does not add an error to the record" do
        allow(errors).to receive(:add)
        subject
        expect(errors).not_to have_received(:add)
      end
    end

    context "when the email is invalid due to regex" do
      let(:telephone_number) { "invalid-format" }

      it "adds an error to the record" do
        allow(errors).to receive(:add)
        subject
        expect(errors).to have_received(:add)
        .with(:telephone_number,
              "Enter a telephone number, like 01632 960 001, 07700 900 982 or +44 808 157 0192")
      end
    end
  end
end
