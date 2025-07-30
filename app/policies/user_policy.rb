class UserPolicy < ApplicationPolicy
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
