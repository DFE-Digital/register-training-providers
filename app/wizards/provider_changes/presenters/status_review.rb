module ProviderChanges
  module Presenters
    class StatusReview < BaseReview
      def format_value(attribute, value)
        case attribute
        when :new_status
          I18n.t("providers.statuses.#{value}")
        when :reasons
          other_reason = wizard.state_store.read.with_indifferent_access["other_reason"]
          ProviderStatusEnum.reason_labels_for(value, other_reason).join(", ")
        else
          super
        end
      end

    private

      def old_value_row
        { key: { text: "Current status" },
          value: { text: wizard.provider.status_label } }
      end

      def change_rows
        rows = [row_for(:new_status, :new_status, label: "New status")]
        rows << row_for(:reasons, :reasons, label: "Reason") unless new_status_is?(ProviderStatusEnum::ACTIVE)
        rows << row_for(:effective_date, :effective_on, label: "Effective date")
        rows
      end

      def new_status_is?(status)
        wizard.state_store.read.with_indifferent_access["new_status"] == status
      end

      def formatted_effective_on(value)
        return "" if value.blank?

        value.to_fs(:govuk)
      end
    end
  end
end
