module ProviderFiltersHelper
  PROVIDER_TYPE_LABELS = {
    "hei" => "Higher education institution (HEI)",
    "scitt_or_school" => "School",
    "other" => "Other"
  }.freeze

  ACCREDITATION_LABELS = {
    "accredited" => "Accredited",
    "unaccredited" => "Not accredited"
  }.freeze

  SHOW_ARCHIVED_LABELS = {
    "show_archived_provider" => "Include archived providers"
  }.freeze
  def filter_checked?(filter_key, value)
    Array(provider_filters[filter_key]).include?(value)
  end

  def providers_path_filters_without(filter_key, value = nil)
    new_values = if value.nil?
                   []
                 else
                   Array(provider_filters[filter_key]) - [value]
                 end

    providers_path(
      params.to_unsafe_h.deep_merge(
        filters: provider_filters.merge(filter_key => new_values)
      )
    )
  end
end
