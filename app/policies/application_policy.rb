class ApplicationPolicy
  attr_reader :user, :record

  def initialize(user, record)
    @user = user
    @record = record
  end

  def index?
    false
  end

  def show?
    false
  end

  def create?
    false
  end

  def new?
    create?
  end

  def update?
    false
  end

  def edit?
    update?
  end

  def destroy?
    false
  end

private

  def can_read_register?
    user.api_user? || user.reg? || user.mr? || user.bat? || user.ro?
  end

  def manage_accreditations_and_partnerships?
    !user.api_user? && (user.reg? || user.mr?)
  end

  class Scope
    def initialize(user, scope)
      @user = user
      @scope = scope
    end

    def resolve
      scope.kept
    end

  private

    attr_reader :user, :scope
  end
end
