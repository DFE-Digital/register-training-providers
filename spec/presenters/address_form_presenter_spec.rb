require "rails_helper"

RSpec.describe AddressFormPresenter do
  let(:form) do
    AddressForm.new(
      address_line_1: "123 Test Street",
      town_or_city: "Test City",
      postcode: "SW1A 1AA"
    )
  end
  let(:provider) { build(:provider, operating_name: "Test Provider") }
  let(:address) { build(:address, id: 123) }

  describe "provider creation context" do
    subject(:presenter) do
      described_class.new(
        form: form,
        provider: provider,
        context: :create_provider
      )
    end

    describe "#provider_creation_context?" do
      it "returns true" do
        expect(presenter.provider_creation_context?).to be true
      end
    end

    describe "#existing_provider_context?" do
      it "returns false" do
        expect(presenter.existing_provider_context?).to be false
      end
    end

    describe "#edit_context?" do
      it "returns false" do
        expect(presenter.edit_context?).to be false
      end
    end

    describe "#form_url" do
      it "returns the create provider addresses path" do
        expect(presenter.form_url).to eq("/providers/new/addresses")
      end
    end

    describe "#form_method" do
      it "returns post" do
        expect(presenter.form_method).to eq(:post)
      end
    end

    describe "#page_title" do
      it "returns 'Add address'" do
        expect(presenter.page_title).to eq("Add address")
      end
    end

    describe "#page_subtitle" do
      it "returns 'Add provider'" do
        expect(presenter.page_subtitle).to eq("Add provider")
      end
    end

    describe "#page_caption" do
      it "returns 'Add provider'" do
        expect(presenter.page_caption).to eq("Add provider")
      end
    end

    describe "#back_path" do
      context "when provider is accredited" do
        let(:provider) { build(:provider, :accredited) }

        it "returns the accreditation path" do
          expect(presenter.back_path).to eq("/providers/new/accreditation")
        end
      end

      context "when provider is unaccredited" do
        let(:provider) { build(:provider, :unaccredited) }

        it "returns the provider details path" do
          expect(presenter.back_path).to eq("/providers/new/details")
        end
      end
    end

    describe "#cancel_path" do
      it "returns the providers path" do
        expect(presenter.cancel_path).to eq("/providers")
      end
    end
  end

  describe "existing provider context" do
    subject(:presenter) do
      described_class.new(
        form: form,
        provider: provider,
        context: :existing_provider
      )
    end

    before do
      allow(provider).to receive(:id).and_return(456)
    end

    describe "#provider_creation_context?" do
      it "returns false" do
        expect(presenter.provider_creation_context?).to be false
      end
    end

    describe "#existing_provider_context?" do
      it "returns true" do
        expect(presenter.existing_provider_context?).to be true
      end
    end

    describe "#edit_context?" do
      it "returns false" do
        expect(presenter.edit_context?).to be false
      end
    end

    describe "#form_url" do
      it "returns the provider addresses path" do
        expect(presenter.form_url).to eq("/providers/456/addresses")
      end
    end

    describe "#form_method" do
      it "returns post" do
        expect(presenter.form_method).to eq(:post)
      end
    end

    describe "#page_title" do
      it "returns 'Add address - provider name'" do
        expect(presenter.page_title).to eq("Add address - Test Provider")
      end
    end

    describe "#page_subtitle" do
      it "returns 'Add address'" do
        expect(presenter.page_subtitle).to eq("Add address")
      end
    end

    describe "#page_caption" do
      it "returns 'Add address - provider name'" do
        expect(presenter.page_caption).to eq("Add address - Test Provider")
      end
    end

    describe "#back_path" do
      it "returns the provider addresses path" do
        expect(presenter.back_path).to eq("/providers/456/addresses")
      end
    end

    describe "#cancel_path" do
      it "returns the provider addresses path" do
        expect(presenter.cancel_path).to eq("/providers/456/addresses")
      end
    end
  end

  describe "edit context" do
    subject(:presenter) do
      described_class.new(
        form: form,
        provider: provider,
        address: address,
        context: :edit
      )
    end

    before do
      allow(provider).to receive(:id).and_return(456)
      allow(address).to receive(:id).and_return(123)
    end

    describe "#provider_creation_context?" do
      it "returns false" do
        expect(presenter.provider_creation_context?).to be false
      end
    end

    describe "#existing_provider_context?" do
      it "returns false" do
        expect(presenter.existing_provider_context?).to be false
      end
    end

    describe "#edit_context?" do
      it "returns true" do
        expect(presenter.edit_context?).to be true
      end
    end

    describe "#form_url" do
      it "returns the provider address path" do
        expect(presenter.form_url).to eq("/providers/456/addresses/123")
      end
    end

    describe "#form_method" do
      it "returns patch" do
        expect(presenter.form_method).to eq(:patch)
      end
    end

    describe "#page_title" do
      it "returns the provider operating name" do
        expect(presenter.page_title).to eq("Test Provider")
      end
    end

    describe "#page_subtitle" do
      it "returns 'Edit address'" do
        expect(presenter.page_subtitle).to eq("Edit address")
      end
    end

    describe "#page_caption" do
      it "returns the provider operating name" do
        expect(presenter.page_caption).to eq("Test Provider")
      end
    end

    describe "#back_path" do
      it "returns the provider addresses path" do
        expect(presenter.back_path).to eq("/providers/456/addresses")
      end
    end

    describe "#cancel_path" do
      it "returns the provider addresses path" do
        expect(presenter.cancel_path).to eq("/providers/456/addresses")
      end
    end
  end
end
