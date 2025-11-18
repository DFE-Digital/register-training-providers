# app/models/authentication_token.rb
# == Schema Information
#
# Table name: authentication_tokens
#
#  id            :uuid             not null, primary key
#  expires_at    :date             not null
#  last_used_at  :datetime
#  revoked_at    :date
#  status        :string           default("active")
#  token_hash    :string           not null
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  api_client_id :uuid             not null
#  created_by_id :uuid             not null
#  revoked_by_id :uuid
#
# Indexes
#
#  index_authentication_tokens_on_api_client_id            (api_client_id)
#  index_authentication_tokens_on_created_by_id            (created_by_id)
#  index_authentication_tokens_on_revoked_by_id            (revoked_by_id)
#  index_authentication_tokens_on_status_and_last_used_at  (status,last_used_at)
#  index_authentication_tokens_on_token_hash               (token_hash) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (api_client_id => api_clients.id)
#  fk_rails_...  (created_by_id => users.id)
#  fk_rails_...  (revoked_by_id => users.id)
#
class AuthenticationToken < ApplicationRecord
  self.implicit_order_column = :created_at

  validates :token_hash, presence: true, uniqueness: true
  validates :expires_at, presence: true
  validate :expires_at_not_too_far_in_future

  SECRET_KEY = Rails.application.key_generator.generate_key("api-token:v1", 32)

  attr_accessor :token

  enum :status, { active: "active", expired: "expired", revoked: "revoked" } do
    event :revoke do
      before do
        self.revoked_at = Time.current
        self.revoked_by ||= Current.user
      end
      transition [:active] => :revoked
    end

    event :expire do
      transition [:active] => :expired
    end
  end

  belongs_to :api_client
  belongs_to :created_by, class_name: "User"
  belongs_to :revoked_by, class_name: "User", optional: true

  scope :will_expire, ->(date = nil) {
    if date.present?
      active.where(expires_at: ..date)
    else
      active.where.not(expires_at: nil)
    end
  }

  scope :by_status_and_last_used_at, -> { order(:status, last_used_at: :desc) }

  def self.create_with_random_token(api_client:, created_by:, expires_at: 6.months.from_now.to_date)
    token = nil
    token_hash = nil

    loop do
      token = "#{Rails.env}_" + SecureRandom.hex(32)
      token_hash = hash_token(token)
      break unless exists?(token_hash:)
    end

    create!(api_client:, created_by:, expires_at:, token_hash:, token:)
  end

  def self.hash_token(unhashed_token)
    OpenSSL::HMAC.hexdigest("SHA256", SECRET_KEY, unhashed_token)
  end

  def self.authenticate(unhashed_token)
    token = find_by(token_hash: hash_token(unhashed_token))

    return nil if token.nil? || !token.active? ||
      (token.expires_at.present? && token.expires_at < Date.current) ||
      (token.revoked_at.present? && token.revoked_at <= Date.current) ||
      token.api_client.discarded?

    token
  end

  def update_last_used_at!
    return if last_used_at&.today?

    update!(last_used_at: Time.current)
  end

private

  def expires_at_not_too_far_in_future
    return if expires_at.blank?

    if expires_at > 6.months.from_now.to_date
      errors.add(:expires_at, "cannot be more than 6 months in the future")
    end
  end
end
