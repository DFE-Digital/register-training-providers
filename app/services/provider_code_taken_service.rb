class ProviderCodeTakenService
  include ServicePattern

  def initialize(code:, effective_on:, provider:)
    @code = code
    @effective_on = effective_on
    @provider = provider
  end

  def call
    return true if Provider.kept.exists?(code:)

    ProviderChange.pending_value_change(attribute: "code", value: code,
                                        effective_on: effective_on).where.not(provider:).exists?
  end

private

  attr_reader :code, :effective_on, :provider
end
