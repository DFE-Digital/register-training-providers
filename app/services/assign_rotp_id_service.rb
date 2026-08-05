class AssignRotpIdService
  include ServicePattern

  MAX_RETRIES = 10

  def initialize(provider)
    @provider = provider
  end

  def call
    attempt = 0

    begin
      provider.rotp_id = RotpIdGeneratorService.call(
        provider.operating_name,
        provider.onboarded_at,
        attempt
      )

      provider.save!
    rescue ActiveRecord::RecordInvalid => e
      raise unless e.record&.errors&.of_kind?(:rotp_id, :taken)

      attempt += 1
      retry if attempt < MAX_RETRIES

      raise
    end

    provider
  end

private

  attr_reader :provider
end
