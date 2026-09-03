module ProviderChanges
  module Presenters
    class CodeReview
      include DfE::Wizard::CheckAnswersPresenter
      include AcademicYearHelper

      def rows
        [{ key: { text: "Old provider code" },
           value: { text: wizard.provider.code } }] +
          [
            row_for(:new_code, :code, label: "New provider code"),
            row_for(:effective_academic_year, :effective_on),
          ].map do |item|
            { key: { text: item.label },
              value: { text: item.formatted_value },
              actions: [{ href: item.change_path, visually_hidden_text: item.label.downcase }] }
          end
      end

      def format_value(attribute, value)
        case attribute
        when :effective_on
          academic_year_label(value.year)
        else
          value
        end
      end
    end
  end
end
