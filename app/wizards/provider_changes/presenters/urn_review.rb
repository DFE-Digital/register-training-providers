module ProviderChanges
  module Presenters
    class UrnReview < BaseReview
      def format_value(attribute, value)
        return value.presence || "Not entered" if attribute == :urn

        super
      end

    private

      def old_value_row
        { key: { text: "Old unique reference number (URN)" },
          value: { text: wizard.provider.urn.presence || "Not entered" } }
      end

      def change_rows
        [
          row_for(:new_urn, :urn, label: "New unique reference number (URN)"),
          row_for(:effective_date, :effective_on, label: "Effective date"),
        ]
      end
    end
  end
end
