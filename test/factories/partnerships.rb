FactoryBot.define do
  factory :partnership do
    association :provider

    accredited_provider { create(:provider, :accredited) }
    duration { (Time.zone.now..) }
  end
end
