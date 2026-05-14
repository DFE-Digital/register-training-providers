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

  def show?
    record.kept?
  end

  def edit?
    record.kept? && user != record
  end

  def update?
    record.kept? && user != record
  end

  def create?
    record.new_record?
  end
end
