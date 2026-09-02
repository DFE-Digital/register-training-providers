class ArchiveInactiveProviders
  include ServicePattern

  def self.age_to_archive_inactive_providers
    3.years.ago
  end

  def call
    providers = Provider.inactive.select do |provider|
      provider if provider.current_inactive_period["start_date"].to_date <= 3.years.ago
    end

    providers.each(&:archive!)
  end
end
