class AuditsQuery
  include ServicePattern

  attr_reader :provider

  def initialize(provider: nil)
    @provider = provider
  end

  def call
    if provider
      provider.own_and_associated_audits.order(created_at: :desc)
    else
      Audited::Audit.order(created_at: :desc)
    end
  end
end

