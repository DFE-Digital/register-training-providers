class PartnerSearch
  class Result
    attr_reader :partners, :limit

    def initialize(partners:, limit:)
      @partners = partners
      @limit = limit
    end
  end

  MIN_QUERY_LENGTH = 2
  DEFAULT_LIMIT = 15

  def initialize(query:, training_partner_search:, limit: DEFAULT_LIMIT)
    @query = query
    @training_partner_search = training_partner_search
    @limit = limit
  end

  def call
    Result.new(providers: specified_partners, limit: limit)
  end

  def specified_partners
    partners = if training_partner_search
                 Provider.where(provider_type: ProviderTypeEnum::UNACCREDITED_PROVIDER_TYPES.keys)
                   .where.not(id: Accreditation.distinct.select(:provider_id))
                   .where(operating_name: query)
               else
                 Provider.accredited.where(name: query)
               end

    partners = partners.search(query) if query
    partners = partners.limit(limit) if limit
    partners.reorder(:operating_name)
  end

private

  attr_reader :query, :training_partner_search
end
