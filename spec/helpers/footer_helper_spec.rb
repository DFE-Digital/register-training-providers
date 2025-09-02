# spec/helpers/footer_helper_spec.rb
require "rails_helper"

RSpec.describe FooterHelper, type: :helper do
  describe "#govuk_footer_component" do
    before do
      allow(helper).to receive(:accessibility_path).and_return("/accessibility")
      allow(helper).to receive(:cookies_path).and_return("/cookies")
      allow(helper).to receive(:privacy_path).and_return("/privacy")
    end

    it "renders the govuk footer with helpful links" do
      html = helper.govuk_footer_component

      expect(html).to include("Helpful links")
      expect(html).to include("/accessibility")
      expect(html).to include("/cookies")
      expect(html).to include("/privacy")
    end
  end
end
