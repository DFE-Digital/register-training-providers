FactoryBot.define do
  factory :provider_academic_cycle do
    provider
    academic_cycle

    initialize_with do
      ProviderAcademicCycle.find_or_create_by!(
        provider:,
        academic_cycle:
      )
    end
  end
end
