module Partnerships
  module Steps
    class AcademicYearsStep
      include DfE::Wizard::Step

      attribute :academic_year_ids, default: -> { [] }

      validate :academic_year_ids_must_not_be_empty
      validate :academic_year_ids_must_be_available

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

      def academic_year_ids_must_be_available
        selected_ids = Array(academic_year_ids).compact_blank.map(&:to_s)
        return if selected_ids.empty?
        return if wizard.blank?
        return if (selected_ids - wizard.eligible_academic_year_ids).empty?

        errors.add(:academic_year_ids, :inclusion)
      end
    end
  end
end
