class AssignRotpIdService
  include ServicePattern

  MAX_RETRIES = 10

  def initialize(provider)
    @provider = provider
  end

  def call
    attempt = 0

    begin
      provider.assign_attributes(
        rotp_id: RotpIdGeneratorService.call(
          provider.operating_name,
          provider.onboarded_at,
          attempt
        )
      )

      provider.save!(validate: false)
    rescue ActiveRecord::RecordNotUnique => e
      attempt += 1
      retry if attempt < MAX_RETRIES

      raise
    end

    provider
  end

private

  attr_reader :provider
end
