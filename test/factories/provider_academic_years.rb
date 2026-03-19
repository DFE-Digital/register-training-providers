FactoryBot.define do
  factory :provider_academic_year do
    provider
    academic_year

    initialize_with do
      ProviderAcademicYear.find_or_create_by!(
        provider:,
        academic_year:
      )
    end
  end
end
