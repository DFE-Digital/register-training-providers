class ApiClientPolicy < ApplicationPolicy
  class Scope < Scope
    def resolve
      if user.api_user?
        scope.where(created_by: user).kept
      else
        scope.kept
      end
    end
  end

  def show?
    record.kept?
  end

  def edit?
    record.kept?
  end

  def update?
    record.kept?
  end

  def destroy?
    record.kept?
  end

  def create?
    record.new_record?
  end
end
