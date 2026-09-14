module ProviderChanges
  module Presenters
    class UkprnReview < BaseReview
    private

      def old_value_row
        { key: { text: "Old UK provider reference number (UKPRN)" },
          value: { text: wizard.provider.ukprn } }
      end

      def change_rows
        [
          row_for(:new_ukprn, :ukprn, label: "New UK provider reference number (UKPRN)"),
          row_for(:effective_date, :effective_on, label: "Effective date"),
        ]
      end
    end
  end
end
