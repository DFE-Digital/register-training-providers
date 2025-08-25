class ProvidersQuery
  include ServicePattern

  PROVIDER_TYPE_MAPPINGS = {
    "scitt_or_school" => %w[scitt school]
  }.freeze

  VALID_PROVIDER_TYPES = %w[hei scitt school other].freeze
  VALID_ACCREDITATION_STATUSES = %w[accredited unaccredited].freeze

  attr_reader :relation, :filters, :search_term

  def initialize(relation = Provider.all, filters: {}, search_term: nil)
    @relation = relation
    @filters  = filters
    @search_term = search_term
  end

  def call
    return relation.none if invalid_filter_combination?

    scope = filter_by_provider_type(relation)
    scope = filter_by_accreditation_status(scope)
    scope = filter_by_archived(scope)

    scope = scope.search(search_term) if search_term.present?
    scope
  end

private

  def sanitised_provider_types
    @sanitised_provider_types ||= Array(filters[:provider_types])
      .flat_map { |type| PROVIDER_TYPE_MAPPINGS[type] || type }
      .select { |type| VALID_PROVIDER_TYPES.include?(type) }
  end

  def sanitised_accreditation_statuses
    @sanitised_accreditation_statuses ||= Array(filters[:accreditation_statuses]) & VALID_ACCREDITATION_STATUSES
  end

  def invalid_filter_combination?
    (filters[:provider_types].present? && sanitised_provider_types.empty?) ||
      (filters[:accreditation_statuses].present? && sanitised_accreditation_statuses.empty?)
  end

  def filter_by_provider_type(scope)
    return scope if sanitised_provider_types.blank?

    scope.where(provider_type: sanitised_provider_types)
  end

  def filter_by_accreditation_status(scope)
    return scope if sanitised_accreditation_statuses.blank?

    allowed_statuses =
      if sanitised_provider_types.present?
        sanitised_provider_types.flat_map { |provider_type|
          case provider_type
          when "scitt"  then ["accredited"]
          when "school" then ["unaccredited"]
          else VALID_ACCREDITATION_STATUSES
          end
        }.uniq
      else
        sanitised_accreditation_statuses
      end

    filtered_statuses = sanitised_accreditation_statuses & allowed_statuses
    return scope.none if filtered_statuses.empty?

    scope.where(accreditation_status: filtered_statuses)
  end

  def filter_by_archived(scope)
    Array(filters[:show_archived]).include?("show_archived_provider") ? scope : scope.where(archived_at: nil)
  end
end
