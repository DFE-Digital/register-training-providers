module WizardDateComponents
  extend ActiveSupport::Concern

  included do
    include GovukDateComponents
  end

  def initialize(step_attributes = {})
    super(**self.class.build_date_attributes(step_attributes))
  end

  class_methods do
    # Reconciles the various shapes a step can be hydrated with:
    #  1. GOV.UK date params ("effective_on(3i)") from a submitted form
    #  2. day/month/year attributes from the state store
    #  3. a bare date (e.g. an existing ProviderChange being restored)
    # and normalises them all onto the day/month/year attributes.
    def build_date_attributes(step_attributes)
      params = step_attributes.to_h.each_with_object({}) do |(key, value), acc|
        symbol_key = key.to_sym

        converted_key = if const_defined?(:PARAM_CONVERSION)
                          const_get(:PARAM_CONVERSION).fetch(symbol_key.to_s, symbol_key).to_sym
                        else
                          symbol_key
                        end

        acc[converted_key] = value
      end

      materialise_date_components(params)
    end

  private

    def materialise_date_components(params)
      return params unless const_defined?(:DATE_FIELDS)

      const_get(:DATE_FIELDS).each do |field|
        date = params[field]
        next if date.blank? || params[:"#{field}_day"].present?

        params[:"#{field}_day"] = date.day
        params[:"#{field}_month"] = date.month
        params[:"#{field}_year"] = date.year
      end

      params
    end
  end
end
