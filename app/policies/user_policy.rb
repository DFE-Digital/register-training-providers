class UserPolicy < ApplicationPolicy
  class Scope < Scope
    def resolve
      if user.api_user?
        scope.none
      else
        scope.kept
      end
    end
  end

  def index?
    !user.api_user?
  end

  def show?
    record.kept? && !user.api_user
  end

  def edit?
    record.kept? && user != record && !user.api_user && !record.system_admin?
  end

  def update?
    record.kept? && user != record && !user.api_user && !record.system_admin?
  end

  def create?
    record.new_record? && !user.api_user
  end

  def destroy?
    record.kept? && user != record && !user.api_user && !record.system_admin?
  end
end
