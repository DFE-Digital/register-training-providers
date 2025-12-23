module Partnerships
  class AcademicCyclesForm
    include ActiveModel::Model
    include ActiveModel::Attributes
    include ActiveModel::Validations::Callbacks

    attr_accessor :academic_cycle_ids

    validate :academic_cycle_ids_must_not_be_empty

    def self.model_name
      ActiveModel::Name.new(self, nil, "AcademicCycles")
    end

    def self.i18n_scope
      :activerecord
    end

  private

    def academic_cycle_ids_must_not_be_empty
      return true unless academic_cycle_ids.empty?

      errors.add(:academic_cycle_ids, :blank)
    end
  end
end
