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

    context "when the provider is archived" do
      let(:provider) { create(:provider, code: "OLD", archived_at: Time.zone.now) }
      let(:provider_change) do
        create(:provider_change, provider: provider, value: "ABC")
      end

      it "marks the change as failed" do
        expect { perform }
          .to change { provider_change.reload.status }
          .from("pending").to("failed")
      end

      it "records that the provider is archived" do
        perform

        expect(provider_change.reload.error_message).to eq("Provider is archived")
        expect(provider_change.reload.processed_at).to be_present
      end

      it "does not apply the change to the provider" do
        expect { perform }
          .not_to(change { provider_change.provider.reload.code })
      end

      context "when the change is a status change" do
        let(:provider_change) do
          create(:provider_change, :status_change, provider: provider,
                                                   value: { "status" => "inactive", "reason_ids" => ["no_current_cohorts"] })
        end

        it "marks the change as failed" do
          expect { perform }
            .to change { provider_change.reload.status }
            .from("pending").to("failed")

          expect(provider_change.error_message).to eq("Provider is archived")
        end

        it "does not create an inactive period" do
          expect { perform }
            .not_to(change { provider.reload.inactive_periods })
        end
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

    context "when the change has already failed" do
      let(:provider_change) do
        create(:provider_change, provider: create(:provider, code: "OLD"), value: "ABC", status: :failed)
      end

      it "does not apply the change to the provider" do
        expect { perform }
          .not_to(change { provider_change.provider.reload.code })
      end
    end

    context "when the provider has since been discarded" do
      let(:provider) { create(:provider, code: "OLD") }
      let(:provider_change) do
        create(:provider_change, provider: provider, value: "ABC")
      end

      before { provider.discard! }

      it "does not apply the change to the provider" do
        expect { perform }
          .not_to(change { provider.reload.code })
      end

      it "marks the change as failed with a discarded-provider message" do
        expect { perform }
          .to change { provider_change.reload.status }
          .from("pending").to("failed")

        expect(provider_change.error_message).to eq("Provider was discarded before the change could be applied")
      end

      it "records when the change was processed" do
        expect { perform }
          .to change { provider_change.reload.processed_at }
          .from(nil)
      end

      context "when the change is a status change" do
        let(:provider_change) do
          create(:provider_change, :status_change, provider: provider,
                                                   value: { "status" => "inactive", "reason_ids" => ["no_current_cohorts"] })
        end

        it "marks the change as failed with a discarded-provider message" do
          expect { perform }
            .to change { provider_change.reload.status }
            .from("pending").to("failed")

          expect(provider_change.error_message).to eq("Provider was discarded before the change could be applied")
        end

        it "does not create an inactive period" do
          expect { perform }
            .not_to(change { provider.reload.inactive_periods })
        end
      end
    end

    context "when the change is failed by a mid-apply archive" do
      let(:provider) { create(:provider) }
      let(:provider_change) do
        create(:provider_change, :status_change, provider: provider, value: { "status" => "inactive" })
      end

      before do
        provider_change # materialise before the stub

        allow(Providers::ApplyStatusChangeService).to receive(:call) do
          provider.archive! # fails the pending change
          raise StandardError, "archive landed mid-apply"
        end
      end

      it "does not raise out of the job" do
        expect { perform }.not_to raise_error
      end

      it "leaves the change failed and the provider archived" do
        perform

        expect(provider_change.reload).to be_failed
        expect(provider.reload).to be_archived
      end

      it "keeps the failure reason recorded by the archive" do
        perform

        expect(provider_change.reload.error_message)
          .to eq("Provider was archived before the change took effect")
      end
    end

    context "when the provider is archived while the change is being applied" do
      let(:provider) { create(:provider) }
      let(:provider_change) do
        create(:provider_change, :status_change, provider: provider, value: { "status" => "inactive" })
      end

      before do
        provider_change # materialise before the stub

        allow(Providers::ApplyStatusChangeService).to receive(:call) do
          provider.archive!
          true
        end
      end

      it "keeps the failure recorded by the archive instead of completing the change" do
        perform

        expect(provider_change.reload).to be_failed
        expect(provider_change.error_message)
          .to eq("Provider was archived before the change took effect")
      end
    end

    context "when a generic change is applied after the provider is archived behind the row lock" do
      let(:provider) { create(:provider, code: "OLD") }
      let(:provider_change) do
        create(:provider_change, provider: provider, value: "ABC")
      end

      before do
        provider_change # materialise before the stub

        allow_any_instance_of(Provider).to receive(:with_lock).and_wrap_original do |original, &block|
          provider.update_columns(archived_at: Time.current)
          original.call(&block)
        end
      end

      it "fails the change without applying it" do
        perform

        expect(provider_change.reload).to be_failed
        expect(provider_change.error_message).to eq("Provider was archived before the change could be applied")
        expect(provider.reload.code).to eq("OLD")
      end
    end

    context "when applying the change raises" do
      let(:provider) { create(:provider) }
      let(:provider_change) do
        create(:provider_change, :status_change, provider: provider, value: { "status" => "inactive" })
      end

      before do
        allow(Providers::ApplyStatusChangeService)
          .to receive(:call).and_raise(StandardError, "lock wait timeout")
      end

      it "marks the change as failed instead of aborting" do
        expect { perform }.not_to raise_error

        expect(provider_change.reload).to be_failed
        expect(provider_change.error_message).to eq("lock wait timeout")
      end

      it "records when the change was processed" do
        expect { perform }
          .to change { provider_change.reload.processed_at }
          .from(nil)
      end

      it "leaves the provider untouched" do
        expect { perform }
          .not_to(change { provider.reload.status })
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

    context "when the change is a status change" do
      let(:provider) { create(:provider) }
      let(:provider_change) do
        create(:provider_change, :status_change, provider: provider, effective_on: Date.current,
                                                 value: { "status" => new_status, "reason_ids" => ["no_current_cohorts"], "other_reason" => other_reason })
      end

      let(:new_status) { "inactive" }
      let(:other_reason) { nil }

      it "applies the status transition" do
        expect { perform }
          .to change { provider_change.provider.reload.status }
          .from("active").to("inactive")

        expect(provider_change.reload).to be_completed
        expect(provider.reload.inactive_periods.sole["reasons_for_inactive"]).to eq(["No current cohorts"])
      end

      context "with a custom reason" do
        let(:other_reason) { "Custom reason" }
        let(:provider_change) do
          create(:provider_change, :status_change, provider: provider, effective_on: Date.current,
                                                   value: { "status" => new_status, "reason_ids" => %w[no_current_cohorts other], "other_reason" => other_reason })
        end

        it "records the custom reason label" do
          perform

          expect(provider.reload.inactive_periods.sole["reasons_for_inactive"])
            .to eq(["No current cohorts", "Custom reason"])
        end
      end

      context "when the new status is not a transitionable status" do
        let(:new_status) { "archived" }

        it "marks the change as failed" do
          expect { perform }
            .to change { provider_change.reload.status }
            .from("pending").to("failed")

          expect(provider_change.reload.error_message).to include("Status cannot change from active to archived")
        end
      end
    end
  end
end
