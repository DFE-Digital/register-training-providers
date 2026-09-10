require "rails_helper"

RSpec.describe Providers::ApplyProviderChangeJob, type: :job do
  subject(:perform) { described_class.new.perform(provider_change.id) }

  let(:provider_change) do
    create(:provider_change, provider: create(:provider, code: "OLD"), value: "ABC")
  end

  describe "#perform" do
    it "applies the change to the provider" do
      expect { perform }
        .to change { provider_change.provider.reload.code }
        .from("OLD").to("ABC")
    end

    it "marks the change as completed" do
      expect { perform }
        .to change { provider_change.reload.status }
        .from("pending").to("completed")
    end

    it "records when the change was processed" do
      expect { perform }
        .to change { provider_change.reload.processed_at }
        .from(nil)
    end

    context "when the change is not yet effective" do
      let(:provider_change) do
        create(:provider_change, provider: create(:provider, code: "OLD"), value: "ABC",
                                 effective_on: Date.current + 1.day)
      end

      it "does not apply the change to the provider" do
        expect { perform }
          .not_to(change { provider_change.provider.reload.code })
      end

      it "leaves the change pending" do
        expect { perform }
          .not_to(change { provider_change.reload.status })
      end
    end

    context "when the change is already completed" do
      let(:provider_change) do
        create(:provider_change, provider: create(:provider, code: "OLD"), value: "ABC", status: :completed)
      end

      it "does not apply the change to the provider" do
        expect { perform }
          .not_to(change { provider_change.provider.reload.code })
      end
    end

    context "when the value is not valid for the provider" do
      let(:provider_change) do
        create(:provider_change, provider: create(:provider, code: "OLD"), value: "AAAA")
      end

      it "marks the change as failed" do
        expect { perform }
          .to change { provider_change.reload.status }
          .from("pending").to("failed")
      end

      it "records the reason the change failed" do
        expect { perform }
          .to change { provider_change.reload.error_message }
          .from(nil)
      end

      it "keeps the provider code unchanged" do
        expect { perform }
          .not_to(change { provider_change.provider.reload.code })
      end
    end
  end
end
