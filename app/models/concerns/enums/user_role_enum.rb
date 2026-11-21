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
    enum :role, USER_ROLES, validate: { allow_nil: true }
  end

  def self.label_for(value)
    return "Not applicable" if value.blank?

    I18n.t("users.roles.#{value}", default: value.to_s.humanize)
  end

  def self.description_for(value)
    return if value.blank?

    I18n.t("users.role_descriptions.#{value}", default: "")
  end

  def role_label
    UserRoleEnum.label_for(role)
  end

  def role_description
    UserRoleEnum.description_for(role)
  end
end
