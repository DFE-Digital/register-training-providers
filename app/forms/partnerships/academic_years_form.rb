module Partnerships
  class AcademicYearsForm
    include ActiveModel::Model
    include ActiveModel::Attributes
    include ActiveModel::Validations::Callbacks

    attr_accessor :academic_year_ids

    validate :academic_year_ids_must_not_be_empty

    def self.model_name
      ActiveModel::Name.new(self, nil, "AcademicYears")
    end

    def self.i18n_scope
      :activerecord
    end

  private

    def academic_year_ids_must_not_be_empty
      return true unless academic_year_ids.empty?

      errors.add(:academic_year_ids, :blank)
    end
  end
end
