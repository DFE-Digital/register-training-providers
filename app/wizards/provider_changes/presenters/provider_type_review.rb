module ProviderChanges
  module Presenters
    class ProviderTypeReview < BaseReview
      def format_value(attribute, value)
        return provider_type_label(value) if attribute == :provider_type

        super
      end

    private

      def old_value_row
        { key: { text: "Old provider type" },
          value: { text: provider_type_label(wizard.provider.provider_type) } }
      end

      def change_rows
        [
          row_for(:new_provider_type, :provider_type, label: "New provider type"),
          row_for(:effective_date, :effective_on, label: "Effective date"),
        ]
      end

      def provider_type_label(value)
        ProviderTypeEnum.label_for(value)
      end
    end
  end
end
