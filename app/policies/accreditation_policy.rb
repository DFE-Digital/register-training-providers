class AccreditationPolicy < ApplicationPolicy
  class Scope < Scope
    def resolve
      scope.kept
    end
  end

  def index?
    provider.present? && provider_policy.show?
  end

  def show?
    index?
  end

  def new?
    manage?
  end

  def create?
    manage?
  end

  def edit?
    manage?
  end

  def update?
    manage?
  end

  def destroy?
    manage?
  end

private

  def provider_policy
    @provider_policy ||= ProviderPolicy.new(user, provider)
  end

  def manage?
    return manage_accreditations_and_partnerships? if provider_creation_mode?

    return false if provider.nil?

    ProviderPolicy.new(user, provider).manage_accreditations?
  end

  def provider_creation_mode?
    record.respond_to?(:provider_creation_mode?) && record.provider_creation_mode?
  end

  def provider
    if record.respond_to?(:provider) && record.provider&.persisted?
      record.provider
    elsif record.respond_to?(:provider_id) && record.provider_id.present?
      Provider.find(record.provider_id)
    end
  end
end
