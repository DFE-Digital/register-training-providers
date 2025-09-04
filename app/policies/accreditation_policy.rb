class AccreditationPolicy < ApplicationPolicy
  class Scope < Scope
    def resolve
      scope.kept
    end
  end

  def index?
    provider_policy.show?
  end

  delegate :show?, to: :provider_policy

  def new?
    provider_policy.edit?
  end

  def create?
    provider_policy.edit?
  end

  delegate :edit?, to: :provider_policy

  def update?
    provider_policy.edit?
  end

  def destroy?
    provider_policy.edit?
  end

private

  def provider_policy
    @provider_policy ||= ProviderPolicy.new(user, provider)
  end

  def provider
    # Handle both real accreditations and form objects
    if record.respond_to?(:provider) && record.provider.present?
      record.provider
    elsif record.respond_to?(:provider_id) && record.provider_id.present?
      Provider.find(record.provider_id)
    else
      raise "Unable to determine provider for accreditation authorization"
    end
  end
end
