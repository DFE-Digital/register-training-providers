class UserPolicy < ApplicationPolicy
  class Scope < Scope
    def resolve
      return scope.none unless user.reg?

      scope.kept
    end
  end

  def index?
    user.reg?
  end

  def show?
    user.reg? && record.kept?
  end

  def edit?
    user.reg? && record.kept? && user != record && !record.system_admin?
  end

  def update?
    edit?
  end

  def create?
    user.reg? && record.new_record?
  end

  def destroy?
    edit?
  end
end
