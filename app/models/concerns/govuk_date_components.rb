module GovukDateComponents
  extend ActiveSupport::Concern

  class_methods do
    def has_date_components(*date_fields)
      @date_fields = date_fields.freeze

      date_fields.each do |date_field|
        attribute :"#{date_field}_day", :integer
        attribute :"#{date_field}_month", :integer
        attribute :"#{date_field}_year", :integer
        attribute date_field, :date
      end

      const_set(:DATE_FIELDS, date_fields.freeze)
      const_set(:PARAM_CONVERSION, build_param_conversion(date_fields).freeze)
    end

  private

    def build_param_conversion(date_fields)
      date_fields.flat_map { |date_field|
        [
          ["#{date_field}(3i)", "#{date_field}_day"],
          ["#{date_field}(2i)", "#{date_field}_month"],
          ["#{date_field}(1i)", "#{date_field}_year"]
        ]
      }.to_h
    end
  end

  def extract_date_components_from(source_object)
    form_attributes = {}

    self.class::DATE_FIELDS.each do |date_field|
      date_value = source_object.public_send(date_field)
      form_attributes[date_field] = date_value

      next if date_value.blank?

      form_attributes[:"#{date_field}_day"] = date_value.day
      form_attributes[:"#{date_field}_month"] = date_value.month
      form_attributes[:"#{date_field}_year"] = date_value.year
    end

    form_attributes
  end

  def serializable_hash(_options = nil)
    base_hash = respond_to?(:attributes) ? attributes : {}
    return base_hash unless defined?(self.class::DATE_FIELDS)

    date_attributes = self.class::DATE_FIELDS.flat_map { |date_field|
      [
        [date_field.to_s, public_send(date_field)],
        ["#{date_field}_day", public_send("#{date_field}_day")],
        ["#{date_field}_month", public_send("#{date_field}_month")],
        ["#{date_field}_year", public_send("#{date_field}_year")]
      ]
    }.to_h

    base_hash.merge(date_attributes)
  end

private

  def convert_date_components
    self.class::DATE_FIELDS.each do |date_field|
      public_send("#{date_field}=", build_date_from_components(date_field))
    end
  end

  def build_date_from_components(date_field)
    year = send("#{date_field}_year")
    month = send("#{date_field}_month")
    day = send("#{date_field}_day")

    return nil unless year.present? && month.present? && day.present?

    begin
      Date.new(year, month, day)
    rescue ArgumentError
      nil
    end
  end
end
