module ProviderChanges
  module Presenters
    class LegalNameReview < BaseReview
      def format_value(attribute, value)
        return value.presence || "Not entered" if attribute == :legal_name

        super
      end

    private

      def old_value_row
        { key: { text: "Old legal name" },
          value: { text: wizard.provider.legal_name.presence || "Not entered" } }
      end

      def change_rows
        [
          row_for(:new_legal_name, :legal_name, label: "New legal name"),
          row_for(:effective_date, :effective_on, label: "Effective date"),
        ]
      end
    end
  end
end
