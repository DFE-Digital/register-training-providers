class SaveProviderChangeService
  include ServicePattern

  # Two overlapping "Confirm and continue" submits of the same wizard race:
  # the first applies the change synchronously, so the second no longer
  # finds a pending row and would append an identical history row. Inside
  # the provider row lock, an identically-valued, identically-dated change
  # completed within this window is treated as the same submission and
  # reused instead of being recorded twice.
  IDENTICAL_CONFIRM_REUSE_WINDOW = 1.hour

  def initialize(provider:, attribute_name:, attributes:, creator:)
    @provider = provider
    @attribute_name = attribute_name
    @attributes = attributes
    @creator = creator
  end

  def call
    ProviderChangeBaselineService.call(provider:, attribute_name:)

    # Serialises racing confirms on the provider row the archive/apply
    # paths already contend on, so the reuse check cannot pass for two
    # overlapping submissions.
    provider.with_lock do
      recently_applied_duplicate || record_change
    end
  end

private

  attr_reader :provider, :attribute_name, :attributes, :creator

  def recently_applied_duplicate
    duplicate = provider.provider_changes
      .requested
      .completed
      .for_attribute(attribute_name)
      .where(value: attributes[:value], effective_on: attributes[:effective_on])
      .where("created_at > ?", IDENTICAL_CONFIRM_REUSE_WINDOW.ago)
      .order(created_at: :desc)
      .first

    return if duplicate.blank?

    # Only the latest completed change for the attribute may be reused. If a
    # later one exists, this is a genuine new transition (e.g. A -> B -> A -> B)
    # and reusing the older row would silently drop the submission.
    return if provider.provider_changes
      .completed
      .for_attribute(attribute_name)
      .exists?(["created_at > ?", duplicate.created_at])

    duplicate
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
