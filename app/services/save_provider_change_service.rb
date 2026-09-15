class SaveProviderChangeService
  include ServicePattern

  def initialize(provider:, attribute_name:, attributes:, creator:)
    @provider = provider
    @attribute_name = attribute_name
    @attributes = attributes
    @creator = creator
  end

  def call
    provider_change = provider.provider_changes.pending.find_or_initialize_by(
      attribute_name:
    )

    provider_change.update!(
      **attributes,
      creator:
    )

    if provider_change.effective_on <= Date.current
      Providers::ApplyProviderChangeJob.perform_now(provider_change.id)
    end

    provider_change
  end

private

  attr_reader :provider, :attribute_name, :attributes, :creator
end
