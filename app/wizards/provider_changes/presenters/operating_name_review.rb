module ProviderChanges
  module Presenters
    class OperatingNameReview < BaseReview
    private

      def old_value_row
        { key: { text: "Old operating name" },
          value: { text: wizard.provider.operating_name } }
      end

      def change_rows
        [
          row_for(:new_operating_name, :operating_name, label: "New operating name"),
          row_for(:effective_date, :effective_on, label: "Effective date"),
        ]
      end
    end
  end
end
