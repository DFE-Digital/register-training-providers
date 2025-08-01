class ProviderPolicy < ApplicationPolicy
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
