module ProviderChanges
  module Presenters
    class CodeReview < BaseReview
      include AcademicYearHelper

    private

      def old_value_row
        { key: { text: "Old provider code" },
          value: { text: wizard.provider.code } }
      end

      def change_rows
        [
          row_for(:new_code, :code, label: "New provider code"),
          row_for(:effective_academic_year, :effective_on),
        ]
      end

      def formatted_effective_on(value)
        academic_year_label(value.year)
      end
    end
  end
end
