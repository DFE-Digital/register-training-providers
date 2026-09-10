module ProviderChanges
  module Steps
    class EffectiveAcademicYearStep
      include DfE::Wizard::Step
      include AcademicYearHelper

      attribute :effective_on, :date

      validates :effective_on,
                inclusion: {
                  in: ->(step) { [step.next_academic_year_start_date, step.following_academic_year_start_date] }
                }

      validate :code_is_available, unless: -> { errors.key?(:effective_on) }

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

      def code_is_available
        code = wizard.state_store.code
        return if code.blank?

        own_claim = wizard.provider.provider_changes.pending_value_change(
          attribute: "code", value: code, effective_on: effective_on
        )
        return if own_claim.exists? && following_academic_year_start_date == effective_on

        errors.add(:effective_on, :taken) if ProviderCodeTakenService.call(
          code: code, effective_on: effective_on, provider: wizard.provider
        )
      end
    end
  end
end
