class ProviderPolicy < ApplicationPolicy
  class Scope < Scope
    def resolve
      scope.kept
    end
  end

  def index?
    can_read_register?
  end

  def show?
    record.kept? && can_read_register?
  end

  def edit?
    record.kept? && record.not_archived? && can_edit?
  end

  def update?
    edit?
  end

  def create?
    record.new_record? && can_create?
  end

  def destroy?
    record.kept? && record.archived? && user.reg?
  end

  def restore?
    record.kept? && record.archived? && user.reg?
  end

  def archive?
    record.kept? && !record.archived? && record.status == ProviderStatusEnum::INACTIVE && can_edit?
  end

  def manage_accreditations?
    record.kept? && record.not_archived? && manage_accreditations_and_partnerships?
  end

  def manage_partnerships?
    record.kept? && record.not_archived? && manage_accreditations_and_partnerships?
  end

  def any_write_access?
    update? || restore? || manage_accreditations? || manage_partnerships?
  end

  # The provider-level buttons rendered in the page header: edit, archive,
  # restore/delete and the active/inactive toggle. Deliberately a strict subset
  # of #any_write_access? — MR can manage partnerships on an unaccredited
  # provider without any provider-level button to offer.
  def any_action_buttons?
    update? || restore?
  end

private

  def can_edit?
    return false if user.api_user?
    return true if user.reg?
    return user.mr? if record.accredited?
    return user.bat? if record.unaccredited?

    false
  end

  def can_create?
    return false if user.api_user?
    return true if user.reg?
    return user.mr? || user.bat? unless record.respond_to?(:accreditation_status)

    case record.accreditation_status
    when AccreditationStatusEnum::ACCREDITED then user.mr?
    when AccreditationStatusEnum::UNACCREDITED then user.bat?
    else user.mr? || user.bat?
    end
  end
end
