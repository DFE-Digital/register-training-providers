class ProviderPolicy < ApplicationPolicy
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
    true
  end

  def show?
    record.kept?
  end

  def edit?
    record.kept? && record.not_archived?
  end

  def update?
    record.kept? && record.not_archived?
  end

  def create?
    record.new_record?
  end
end
