class SaveProviderChangeService
  include ServicePattern

  IDENTICAL_CONFIRM_REUSE_WINDOW = 1.hour

  def initialize(provider:, attribute_name:, attributes:, creator:)
    @provider = provider
    @attribute_name = attribute_name
    @attributes = attributes
    @creator = creator
  end

  def call
    ProviderChangeBaselineService.call(provider:, attribute_name:)

    provider.with_lock do
      recently_applied_duplicate || record_change
    end
  end

private

  attr_reader :provider, :attribute_name, :attributes, :creator

  def recently_applied_duplicate
    return if pending_change?

    duplicate = latest_identical_recent_change
    return if duplicate.blank?
    return if superseded_by_later_change?(duplicate)

    duplicate
  end

  def pending_change?
    provider.provider_changes.pending.for_attribute(attribute_name).exists?
  end

  def latest_identical_recent_change
    provider.provider_changes
      .requested
      .completed
      .for_attribute(attribute_name)
      .where(value: attributes[:value], effective_on: attributes[:effective_on])
      .where("created_at > ?", IDENTICAL_CONFIRM_REUSE_WINDOW.ago)
      .order(created_at: :desc)
      .first
  end

  def superseded_by_later_change?(change)
    provider.provider_changes
      .completed
      .for_attribute(attribute_name)
      .exists?(["created_at > ?", change.created_at])
  end

  def record_change
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
end
