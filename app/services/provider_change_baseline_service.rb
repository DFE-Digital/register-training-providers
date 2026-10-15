class ProviderChangeBaselineService
  include ServicePattern

  def initialize(provider:, attribute_name:, status_value: nil)
    @provider = provider
    @attribute_name = attribute_name.to_s
    @status_value = status_value
  end

  def call
    raise ArgumentError, "not a changeable attribute: #{attribute_name}" unless
      ProviderChange::CHANGEABLE_ATTRIBUTES.include?(attribute_name)

    return if original_value_already_lost?

    ActiveRecord::Base.transaction(requires_new: true) do
      provider.provider_changes.create!(
        attribute_name: attribute_name,
        value: baseline_value,
        effective_on: effective_on,
        status: :completed,
        source: :baseline
      )
    end
  rescue ActiveRecord::RecordNotUnique
    nil
  end

private

  attr_reader :provider, :attribute_name, :status_value

  def baseline_value
    # The supplied status lets a caller that has already mutated the provider
    # (restore clears archived_at) still capture the status it held when the
    # change was made, rather than re-reading the post-change status.
    return { "status" => status_value.presence || provider.status } if attribute_name == "status"

    provider.public_send(attribute_name)
  end

  def original_value_already_lost?
    provider.provider_changes.completed.for_attribute(attribute_name).exists?
  end

  def effective_on
    candidate_date = [provider.first_active_at, provider.onboarded_at, provider.created_at.to_date].compact.first

    [candidate_date, Date.current].min
  end
end
