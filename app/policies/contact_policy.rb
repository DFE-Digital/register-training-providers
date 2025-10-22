class ContactPolicy < ApplicationPolicy
  class Scope < Scope
    def resolve
      scope.kept
    end
  end

  def index?
    provider_policy.show?
  end

  delegate :show?, to: :provider_policy

private

  def provider_policy
    @provider_policy ||= ProviderPolicy.new(user, record.provider)
  end
end
