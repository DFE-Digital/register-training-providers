class ApiClientPolicy < ApplicationPolicy
  def show?
    record.kept?
  end

  def edit?
    record.kept?
  end

  def update?
    record.kept?
  end

  def create?
    true # record.new_record?
  end
end
