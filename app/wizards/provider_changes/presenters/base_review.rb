module ProviderChanges
  module Presenters
    class BaseReview
      include DfE::Wizard::CheckAnswersPresenter

      def rows
        [old_value_row] + change_rows.map do |item|
          { key: { text: item.label },
            value: { text: item.formatted_value },
            actions: [{ href: item.change_path, visually_hidden_text: item.label.downcase }] }
        end
      end

      def format_value(attribute, value)
        case attribute
        when :effective_on
          formatted_effective_on(value)
        else
          value
        end
      end

    private

      # Subclasses describe the current value and the rows to confirm.
      def old_value_row
        raise NotImplementedError
      end

      def change_rows
        raise NotImplementedError
      end

      def formatted_effective_on(value)
        value.to_fs(:govuk)
      end
    end
  end
end
