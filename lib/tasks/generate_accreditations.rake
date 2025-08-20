require Rails.root.join("config/environment")

namespace :generate do
  desc "Generate example accreditation data for providers"
  task accreditations: :environment do
    raise "THIS TASK CANNOT BE RUN IN PRODUCTION" if Rails.env.production?

    # Select 50% of providers that can be accredited (exclude schools)
    accreditable_providers = Provider.where.not(provider_type: "school")
    total_accreditable = accreditable_providers.count
    providers_to_accredit = accreditable_providers.order("RANDOM()").limit((total_accreditable * 0.5).round)
    
    puts "Generating accreditations for #{providers_to_accredit.count} out of #{total_accreditable} accreditable providers..."

    providers_to_accredit.each do |provider|
      # Skip if provider already has accreditations
      next if provider.accreditations.exists?

      # Determine the prefix based on provider type
      prefix = case provider.provider_type
               when "hei"
                 "1"
               when "scitt"
                 "5"
               else
                 # For 'other' provider types, randomly choose between 1 or 5
                 ["1", "5"].sample
               end

      # Generate 1 or 2 accreditations for this provider
      num_accreditations = [1, 2].sample

      accreditations_created = 0

      if num_accreditations == 2
        # Create expired accreditation first
        expired_number = generate_unique_accreditation_number(prefix)
        expired_accreditation = provider.accreditations.build(
          number: expired_number,
          start_date: 3.years.ago,
          end_date: 6.months.ago
        )

        expired_accreditation.save!
        accreditations_created += 1
      end

      # Create current/valid accreditation
      current_number = generate_unique_accreditation_number(prefix)
      current_accreditation = provider.accreditations.build(
        number: current_number,
        start_date: 6.months.ago,
        end_date: 1.year.from_now
      )

      current_accreditation.save!
      accreditations_created += 1

      puts "Created #{accreditations_created} accreditation(s) for provider #{provider.code} (#{provider.provider_type})"
    end

    puts "Accreditation generation completed!"
  end

  def generate_unique_accreditation_number(prefix)
    loop do
      number = "#{prefix}#{rand(100..999)}"
      return number unless Accreditation.exists?(number: number)
    end
  end
end
