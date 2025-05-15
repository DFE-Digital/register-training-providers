# == Schema Information
#
# Table name: users
#
#  id                :integer          not null, primary key
#  dfe_sign_in_uid   :string
#  email             :string
#  first_name        :string
#  last_name         :string
#  last_signed_in_at :datetime
#  discarded_at      :datetime
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#
# Indexes
#
#  index_users_on_discarded_at  (discarded_at)
#  index_users_on_email         (email) UNIQUE
#

class User < ApplicationRecord
  include Discard::Model

  audited

  before_validation :sanitise_email

  validates :first_name, presence: true
  validates :last_name, presence: true
  validates :email, presence: true, uniqueness: true

  validate do |record|
    DfeEmailFormatValidator.new(record).validate if email.present?
  end


  private

  def sanitise_email
    self.email = email.gsub(/\s+/, "").downcase unless email.nil?
  end
end
