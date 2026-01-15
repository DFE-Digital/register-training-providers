class PartnershipPolicy < ApplicationPolicy
  class Scope < Scope
    def resolve
      scope.kept
    end
  end

  def index?
    provider_policy.show?
  end

  def new?
    provider_policy.edit?
  end

  def create?
    provider_policy.edit?
  end

  delegate :edit?, to: :provider_policy

private

  def provider_policy
    @provider_policy ||= ProviderPolicy.new(user, record.provider)
  end
end
