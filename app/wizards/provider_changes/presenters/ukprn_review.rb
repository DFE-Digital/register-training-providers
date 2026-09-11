module ProviderChanges
  module Presenters
    class UkprnReview
      include DfE::Wizard::CheckAnswersPresenter

      def rows
        [{ key: { text: "Old UK provider reference number (UKPRN)" },
           value: { text: wizard.provider.ukprn } }] +
          [
            row_for(:new_ukprn, :ukprn, label: "New UK provider reference number (UKPRN)"),
            row_for(:effective_date, :effective_on, label: "Effective date"),
          ].map do |item|
            { key: { text: item.label },
              value: { text: item.formatted_value },
              actions: [{ href: item.change_path, visually_hidden_text: item.label.downcase }] }
          end
      end

      def format_value(attribute, value)
        case attribute
        when :effective_on
          value.to_fs(:govuk)
        else
          value
        end
      end
    end
  end
end
