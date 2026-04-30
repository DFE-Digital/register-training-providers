module Providers
  class AcademicYearsForm
    include ActiveModel::Model
    include ActiveModel::Attributes
    include ActiveModel::Validations::Callbacks
    include SaveAsTemporary

    attribute :provider_id

    attribute :academic_year_ids, default: []

    validate :academic_year_ids_must_not_be_empty

    def self.model_name
      ActiveModel::Name.new(self, nil, "Provider")
    end

    def self.i18n_scope
      :activerecord
    end

    alias_method :serializable_hash, :attributes

    def academic_years
      AcademicYear.where(id: academic_year_ids).ordered_by_duration
    end

    def provider
      @provider ||= Provider.find(provider_id)
    end

    def load_temporary(record_class, purpose:, id: nil, reset: false)
      clear_temporary(record_class, purpose:) if reset

      record_type = record_class.name
      record = temporary_records.find_by(record_type:, purpose:)

      if record&.expired?
        temporary_records.where(record_type:, purpose:).delete_all
        return record_class.new
      end

      if id.present?
        existing_record = record_class.find(id)
        existing_record.assign_attributes(record.rehydrate.attributes.except("id")) if record.present?
        existing_record
      else
        record&.rehydrate || record_class.new
      end
    end

    def clear_temporary(record_class, purpose:)
      temporary_records.where(record_type: record_class.name, purpose: purpose).delete_all
    end

    def save!
      provider.academic_years = academic_years
      provider.save!
    end

  private

    def academic_year_ids_must_not_be_empty
      return true unless academic_year_ids.empty?

      errors.add(:academic_year_ids, :blank)
    end
  end
end
