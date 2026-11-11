module Partnerships
  module Steps
    class AcademicYearsStep
      include DfE::Wizard::Step

      attribute :academic_year_ids, default: -> { [] }

      validate :academic_year_ids_must_not_be_empty

      def self.permitted_params
        [{ academic_year_ids: [] }]
      end

      def self.model_name
        ActiveModel::Name.new(self, nil, "AcademicYears")
      end

      def self.i18n_scope
        :activerecord
      end

    private

      def academic_year_ids_must_not_be_empty
        return if Array(academic_year_ids).compact_blank.present?

        errors.add(:academic_year_ids, :blank)
      end
    end
  end
end
