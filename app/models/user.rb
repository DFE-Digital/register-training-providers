# == Schema Information
#
# Table name: users
#
#  id                :uuid             not null, primary key
#  active            :boolean          default(TRUE), not null
#  api_user          :boolean          default(FALSE), not null
#  dfe_sign_in_uid   :string
#  discarded_at      :datetime
#  email             :string           not null
#  first_name        :string           not null
#  last_name         :string           not null
#  last_signed_in_at :datetime
#  role              :string           not null
#  system_admin      :boolean          default(FALSE), not null
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#
# Indexes
#
#  index_users_on_discarded_at  (discarded_at)
#  index_users_on_email         (email) UNIQUE
#

class User < ApplicationRecord
  self.implicit_order_column = :created_at
  include Discard::Model
  include SaveAsTemporary
  include UserRoleEnum

  has_many :temporary_records, foreign_key: :created_by, dependent: :destroy
  has_many :provider_changes, foreign_key: :created_by_id, inverse_of: :creator, dependent: :nullify
  has_many :api_clients, foreign_key: :created_by_id, dependent: :destroy
  has_many :authentication_tokens, foreign_key: :created_by_id, dependent: :destroy

  MINIMUM_ACTIVE_INTERNAL_USERS = 4

  audited except: [:dfe_sign_in_uid, :last_signed_in_at]

  before_validation :sanitise_email
  before_validation :assign_api_user_role
  before_validation :assign_default_role

  validates :first_name, presence: true
  validates :last_name, presence: true
  validates :email, presence: true, uniqueness: true
  validates :api_user, inclusion: [true, false]
  validates :active, inclusion: [true, false]
  validates :role, presence: true

  validate do |record|
    DfEEmailFormatValidator.new(record).validate if email.present?
  end

  scope :order_by_first_then_last_name, -> { order(:first_name, :last_name) }

  scope :active_internal, -> { kept.where(active: true, api_user: false) }
  scope :active_reg, -> { kept.where(active: true, api_user: false, role: UserRoleEnum::REG) }

  before_discard :discard_all_api_clients!

  after_save :revoke_all_active_tokens_for_api_clients!, unless: :active?

  def self.ensure_minimum_active_users!(users_id_to_exclude:)
    return if find_by(id: users_id_to_exclude)&.api_user?

    remaining = active_internal.where.not(id: users_id_to_exclude)

    raise MinimumActiveUsersError.new(user_id: users_id_to_exclude) if remaining.count < MINIMUM_ACTIVE_INTERNAL_USERS
  end

  def self.ensure_minimum_reg_users!(users_id_to_exclude:)
    return if active_reg.where.not(id: users_id_to_exclude).exists?

    raise MinimumRegUsersError.new(user_id: users_id_to_exclude)
  end

  def self.temporary_purpose(id = nil)
    id.present? ? :"user_#{id}" : :new_user
  end

  def name
    first_name_to_use = first_name_was || first_name
    last_name_to_use = last_name_was || last_name
    "#{first_name_to_use} #{last_name_to_use}"
  end

  def load_temporary(record_class, purpose:, id: nil, reset: false)
    clear_temporary(record_class, purpose:) if reset

    record_type = record_class.name
    record = temporary_records.find_by(record_type:, purpose:)

    if record&.expired?
      temporary_records.where(record_type:, purpose:).delete_all
      return committed_record_or_new(record_class, id)
    end

    if id.present?
      existing_record = record_class.find(id)
      existing_record.assign_attributes(record.rehydrate.attributes.except("id")) if record.present?
      existing_record
    else
      record&.rehydrate || record_class.new
    end
  end

  def clear_temporary(record_class, purpose:)
    temporary_records.where(record_type: record_class.name, purpose: purpose).delete_all
  end

  def clear_temporary_records(record_class)
    temporary_records.where(record_type: record_class.name).delete_all
  end

private

  def sanitise_email
    self.email = email.gsub(/\s+/, "").downcase unless email.nil?
  end

  def assign_api_user_role
    self.role = UserRoleEnum::RO if api_user?
  end

  def assign_default_role
    return if role.present?

    self.role = UserRoleEnum::REG unless persisted?
  end

  def committed_record_or_new(record_class, id)
    id.present? ? record_class.find(id) : record_class.new
  end

  def discard_all_api_clients!
    api_clients.kept.find_each(&:discard!)
  end

  def revoke_all_active_tokens_for_api_clients!
    api_clients.kept.find_each(&:revoke_all_active_tokens!)
  end
end
