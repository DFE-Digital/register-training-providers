class PartnershipPolicy < ApplicationPolicy
  class Scope < Scope
    def resolve
      scope.kept
    end
  end

  def index?
    provider_policy.show?
  end

private

  def provider_policy
    @provider_policy ||= ProviderPolicy.new(user, record.provider)
  end
end
