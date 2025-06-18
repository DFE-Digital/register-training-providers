FactoryBot.define do
  factory :temporary_record do
    association :creator, factory: :user

    expires_at { 1.day.from_now }

    for_user_model
    with_purpose

    trait :expired do
      expires_at { 1.day.ago }
    end

    trait :for_user_model do
      record_type { "User" }
      data { attributes_for(:user) }
    end

    trait :with_purpose do
      transient do
        temp_purpose { "check_your_answers" }
      end

      purpose { temp_purpose }
    end
  end
end
