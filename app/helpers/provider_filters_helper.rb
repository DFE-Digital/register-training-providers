module ProviderFiltersHelper
  def filter_checked?(filter_key, value)
    Array(provider_filters[filter_key]).include?(value.to_s)
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
