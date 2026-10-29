module UserRoleEnum
  extend ActiveSupport::Concern

  USER_ROLES = {
    reg: "reg",
    mr: "mr",
    bat: "bat",
    ro: "ro"
  }.freeze

  REG = USER_ROLES[:reg]
  MR = USER_ROLES[:mr]
  BAT = USER_ROLES[:bat]
  RO = USER_ROLES[:ro]

  included do
    enum :role, USER_ROLES
  end

  def role_label
    return if role.blank?

    I18n.t("users.roles.#{role}")
  end
end
