class ApiClientPolicy < ApplicationPolicy
  class Scope < Scope
    def resolve
      if user.api_user?
        scope.where(created_by: user).kept
      elsif user.reg?
        scope.kept
      else
        scope.none
      end
    end
  end

  def index?
    user.api_user? || user.reg?
  end

  def confirm?
    (user.api_user? || user.reg?) && record.kept? && record.created_by == user
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
    record.new_record? && (user.api_user? || user.reg?)
  end

private

  def user_can_access_record?
    user.api_user? ? record.created_by == user : user.reg?
  end
end
