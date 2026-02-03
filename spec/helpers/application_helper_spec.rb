require "rails_helper"

RSpec.describe ApplicationHelper, type: :helper do
  describe "#provider_page_data" do
    let(:provider) { build_stubbed(:provider, operating_name: "Test College") }

    it "sets the page title and header to the provider's operating name" do
      result = helper.provider_page_data(provider)
      expect(result[:page_title]).to eq("Test College")
      expect(result[:page_header]).to include("Test College")
    end

    context "when provider is archived" do
      let(:provider) { build_stubbed(:provider, :archived) }

      it "includes the Archived tag" do
        result = helper.provider_page_data(provider)
        expect(result[:page_header]).to include("Archived")
      end
    end

    context "when provider is discarded" do
      let(:provider) { build_stubbed(:provider, :discarded) }

      it "includes the Soft deleted tag" do
        result = helper.provider_page_data(provider)
        expect(result[:page_header]).to include("Soft deleted")
      end
    end

    context "when both archived and discarded" do
      let(:provider) { build_stubbed(:provider, :archived, :discarded) }

      it "prefers Soft deleted over Archived" do
        result = helper.provider_page_data(provider)
        expect(result[:page_header]).to include("Soft deleted")
        expect(result[:page_header]).not_to include("Archived")
      end
    end
  end

  describe "#page_data" do
    let(:title) { "Larry Page" }
    let(:caption) { nil }
    let(:header) { nil }
    let(:header_size) { "l" }
    let(:error) { false }
    let(:caption) { nil }

    subject(:result) do
      helper.page_data(title:, header:, header_size:, error:, caption:)
    end

    context "when caption is provided" do
      let(:caption) { "Caption this" }
      let(:header_size) { "m" }

      subject(:result) do
        helper.page_data(title:, header:, header_size:, error:, caption:)
      end

      it "includes the caption in a span with the correct class inside the page_header" do
        expect(result[:page_header]).to include('<span class="govuk-caption-m">Caption this</span>')
      end

      it "includes the header text after the caption" do
        expect(result[:page_header]).to match(/Caption this.*Larry Page/)
      end
    end

    it "sets the page title in content_for" do
      result
      expect(view.content_for(:page_title)).to eq("Larry Page")
    end

    it "returns page_title and page_header" do
      expect(result[:page_title]).to eq("Larry Page")
      expect(result[:page_header]).to include("govuk-heading-l")
      expect(result[:page_header]).to include("Larry Page")
      expect(result[:page_header]).not_to include("govuk-caption-l")
      expect(result[:page_header]).not_to include("Caption")
    end

    context "when caption is set" do
      let(:caption) { "Caption" }
      it "returns page_title and page_header" do
        expect(result[:page_title]).to eq("Larry Page")
        expect(result[:page_header]).to include("govuk-heading-l")
        expect(result[:page_header]).to include("Larry Page")
        expect(result[:page_header]).to include("govuk-caption-l")
        expect(result[:page_header]).to include("Caption")
      end
    end
    context "when error is true" do
      let(:error) { true }

      it "prefixes the title with 'Error: '" do
        result
        expect(view.content_for(:page_title)).to eq("Error: Larry Page")
      end
    end

    context "when header is false" do
      let(:header) { false }

      it "does not set page_header" do
        result
        expect(view.content_for?(:page_header)).to be false
        expect(result).not_to have_key(:page_header)
      end
    end

    context "when header is set explicitly" do
      let(:header) { "No PII" }

      it "uses the provided header text" do
        result
        expect(result[:page_header]).to include("No PII")
        expect(result[:page_header]).to include("govuk-heading-l")
      end
    end
  end

  describe "#govuk_number" do
    context "without precision" do
      it "adds a comma delimiter" do
        expect(helper.govuk_number(1_234_567)).to eq("1,234,567")
      end
    end

    context "with precision" do
      it "adds delimiter and precision" do
        expect(helper.govuk_number(1234.5, precision: 2)).to eq("1,234.50")
      end
    end
  end

  describe "#user_last_signed_in_at" do
    let(:user) { build_stubbed(:user, last_signed_in_at:) }

    context "when the user has never signed in" do
      let(:last_signed_in_at) { nil }

      it "displays that the user has never signed in" do
        expect(helper.user_last_signed_in_at(user)).to eq("User has never signed in")
      end
    end

    context "when the user has signed in" do
      let(:last_signed_in_at) { Time.zone.local(2026, 1, 1) }

      it "displays the date and time the user last signed in" do
        expect(helper.user_last_signed_in_at(user)).to eq("Last signed in at 1 January 2026 at 12am (midnight)")
      end
    end
  end
end
