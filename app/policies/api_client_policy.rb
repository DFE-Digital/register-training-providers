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

  def confirm?
    record.kept? && record.created_by == user
  end

  def show?
    record.kept? && user_can_access_record?
  end

  def edit?
    record.kept? && user_can_access_record?
  end

  def update?
    record.kept? && user_can_access_record?
  end

  def destroy?
    record.kept? && user_can_access_record?
  end

  def create?
    record.new_record?
  end

private

  def user_can_access_record?
    !user.api_user? || record.created_by == user
  end
end
