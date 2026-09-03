module ProviderChanges
  module Steps
    class EffectiveAcademicYearStep
      include DfE::Wizard::Step
      include AcademicYearHelper

      attribute :effective_on, :date

      validates :effective_on, presence: true

      def self.permitted_params
        %i[effective_on]
      end

      def next_academic_year_label
        academic_year_label(AcademicYearCalculator.next_academic_year)
      end

      def following_academic_year_label
        academic_year_label(AcademicYearCalculator.following_academic_year)
      end

      def next_academic_year_start_date
        AcademicYearCalculator.build_academic_year_start_date(AcademicYearCalculator.next_academic_year)
      end

      def following_academic_year_start_date
        AcademicYearCalculator.build_academic_year_start_date(AcademicYearCalculator.following_academic_year)
      end
    end
  end
end
