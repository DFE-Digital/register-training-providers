class AuditsQuery
  include ServicePattern

  SUPPORTED_AUDITABLE_TYPES = %w[Provider Address Accreditation Contact Partnership User].freeze

  attr_reader :provider

  def initialize(provider: nil)
    @provider = provider
  end

  def call
    if provider
      provider_scoped_audits
    else
      all_supported_audits
    end
  end

private

  def all_supported_audits
    Audited::Audit
      .where(auditable_type: SUPPORTED_AUDITABLE_TYPES)
      .order(created_at: :desc)
  end

  def provider_scoped_audits
    provider_own_audits
      .or(provider_associated_audits)
      .or(partnership_audits)
      .order(created_at: :desc)
  end

  def provider_own_audits
    Audited::Audit.where(auditable_type: "Provider", auditable_id: provider.id)
  end

  def provider_associated_audits
    Audited::Audit.where(
      auditable_type: SUPPORTED_AUDITABLE_TYPES,
      associated_type: "Provider",
      associated_id: provider.id
    )
  end

  def partnership_audits
    Audited::Audit.where(
      auditable_type: "Partnership",
      auditable_id: provider.partnerships.select(:id)
    )
  end
end
