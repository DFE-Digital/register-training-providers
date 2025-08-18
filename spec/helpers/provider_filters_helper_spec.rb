require "rails_helper"

RSpec.describe ProviderFiltersHelper, type: :helper do
  describe "PROVIDER_TYPE_LABELS" do
    it "contains the correct labels" do
      expect(ProviderFiltersHelper::PROVIDER_TYPE_LABELS).to eq(
        "hei" => "Higher education institution (HEI)",
        "scitt_or_school" => "School",
        "other" => "Other"
      )
    end
  end

  describe "ACCREDITATION_LABELS" do
    it "contains the correct labels" do
      expect(ProviderFiltersHelper::ACCREDITATION_LABELS).to eq(
        "accredited" => "Accredited",
        "unaccredited" => "Not accredited"
      )
    end
  end

  describe "SHOW_ARCHIVED_LABELS" do
    it "contains the correct label" do
      expect(ProviderFiltersHelper::SHOW_ARCHIVED_LABELS).to eq(
        "show_archived_provider" => "Include archived providers"
      )
    end
  end

  describe "#filter_checked?" do
    before do
      def helper.provider_filters
      end
      allow(helper).to receive(:provider_filters).and_return({
        provider_types: ["hei", "other"],
        accreditation_statuses: ["accredited"],
        show_archived: []
      })
    end

    it "returns true if value is included in filter" do
      expect(helper.filter_checked?(:provider_types, "hei")).to be true
      expect(helper.filter_checked?(:accreditation_statuses, "accredited")).to be true
    end

    it "returns false if value is not included in filter" do
      expect(helper.filter_checked?(:provider_types, "scitt_or_school")).to be false
      expect(helper.filter_checked?(:show_archived, "show_archived_provider")).to be false
    end

    it "returns false if filter_key is missing" do
      expect(helper.filter_checked?(:nonexistent_key, "anything")).to be false
    end
  end

  describe "#providers_path_filters_without" do
    before do
      allow(helper).to receive(:params).and_return(
        ActionController::Parameters.new({
          some_param: "value",
          filters: {
            provider_types: ["hei", "other"],
            accreditation_statuses: ["accredited", "unaccredited"],
            show_archived: ["show_archived_provider"]
          }
        })
      )

      def helper.provider_filters
      end

      allow(helper).to receive(:provider_filters).and_return({
        provider_types: ["hei", "other"],
        accreditation_statuses: ["accredited", "unaccredited"],
        show_archived: ["show_archived_provider"]
      }.with_indifferent_access)
    end

    it "removes a specific value from the filter array" do
      result = helper.providers_path_filters_without(:provider_types, "hei")
      expect(result).to include("filters%5Bprovider_types%5D%5B%5D=other")
      expect(result).not_to include("filters%5Bprovider_types%5D%5B%5D=hei")
    end

    it "returns empty array if value is nil" do
      result = helper.providers_path_filters_without(:show_archived, nil)
      expect(result).not_to include("show_archived")
    end

    it "does not remove other filter values" do
      result = helper.providers_path_filters_without(:accreditation_statuses, "accredited")
      expect(result).to include("filters%5Baccreditation_statuses%5D%5B%5D=unaccredited")
      expect(result).to include("filters%5Bprovider_types%5D%5B%5D=hei")
      expect(result).to include("filters%5Bprovider_types%5D%5B%5D=other")
      expect(result).not_to include("filters%5Baccreditation_statuses%5D%5B%5D=accredited")
    end
  end
end
