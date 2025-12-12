FactoryBot.define do
  factory :partnership do
    association :provider

    accredited_provider { create(:provider, :accredited) }
    duration { (Date.new(Time.zone.now.year, 1, 1)..) }

    after(:create) do |partnership|
      create(:partnership_academic_cycle, partnership:)
    end
  end
end
