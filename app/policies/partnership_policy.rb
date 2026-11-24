class PartnershipPolicy < ApplicationPolicy
  class Scope < Scope
    def resolve
      scope.kept
    end
  end

  def index?
    record.provider.present? && ProviderPolicy.new(user, record.provider).show?
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

  def manage?
    ProviderPolicy.new(user, record.provider).manage_partnerships?
  end
end
