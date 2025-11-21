# spec/factories/authentication_tokens.rb
FactoryBot.define do
  factory :authentication_token do
    api_client
    created_by { association :user }

    expires_at { 1.month.from_now.to_date }
    last_used_at { nil }
    status { "active" }

    transient do
      raw_token { "#{Rails.env}_#{SecureRandom.hex(32)}" }
    end

    token_hash { AuthenticationToken.hash_token(raw_token) }
    token { raw_token }

    trait :expired do
      status { "expired" }
      expires_at { 1.day.ago.to_date }
      revoked_at { nil }
    end

    trait :will_expire do
      status { "active" }
      expires_at { 2.days.from_now.to_date }
    end

    trait :revoked do
      status { "revoked" }
      revoked_at { Date.current }
      revoked_by { association :user }
    end
  end
end
