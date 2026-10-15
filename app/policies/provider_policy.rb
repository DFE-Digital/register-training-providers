class ProviderPolicy < ApplicationPolicy
  class Scope < Scope
    def resolve
      scope.kept
    end
  end

  def index?
    !user.api_user
  end

  def show?
    record.kept? && !user.api_user
  end

  def edit?
    record.kept? && record.not_archived?  && !user.api_user
  end

  def update?
    record.kept? && record.not_archived?  && !user.api_user
  end

  def create?
    record.new_record? && !user.api_user
  end

  def destroy?
    record.kept? && !user.api_user
  end

  def restore?
    record.kept? && record.archived? && !user.api_user
  end
end
